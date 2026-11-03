# Kooshking Umbrel Community App Store

A community Umbrel app store. It currently ships one app:

## TeslaMate (`kooshking-teslamate`)

TeslaMate is a self-hosted data logger for Tesla vehicles: it records drives,
charges, state changes and positions into PostgreSQL and ships Grafana
dashboards for efficiency, battery degradation, charging cost and vampire
drain. This repository only *packages* TeslaMate for Umbrel; TeslaMate itself
is by teslamate-org and is licensed AGPL-3.0
(see https://github.com/teslamate-org/teslamate).

![TeslaMate app icon](icon.png)

### Add this store to Umbrel

1. Open the **App Store** in umbrelOS.
2. Click the **⋯** menu (top right) → **Community App Stores**.
3. Add the store URL: `https://github.com/kooshking123/umbrel-app-store`
4. Open the **Kooshking** store and install **TeslaMate**.

Community app stores are not verified or vetted by the Umbrel team.
Review the source in this repository before installing, as with any
community store.

### First run

1. Open TeslaMate from the Umbrel dashboard (served through Umbrel's app
   proxy, so your Umbrel login protects it).
2. Sign in with a Tesla API access token and refresh token, generated
   beforehand with a token app such as Tesla Auth
   (https://docs.teslamate.org/docs/installation/tokens). TeslaMate never
   asks for your Tesla password.
3. Open Grafana on port 3000 of your Umbrel device and change its default
   `admin` / `admin` login immediately.
4. In TeslaMate, go to Settings → URLs and set the Web App URL to the
   address you open TeslaMate at from the Umbrel dashboard, and the
   Dashboards URL to your Grafana address (for example
   `http://<your-umbrel-ip>:3000`), so the links between TeslaMate and
   Grafana work.

Grafana takes several minutes on its first run while it runs its database
migrations (about six minutes observed on a typical Umbrel). If port 3000
does not answer immediately after install, wait before assuming something
is wrong — see Troubleshooting below.

### How it is wired

- TeslaMate (port 4000) is fronted by Umbrel's `app_proxy`.
- Grafana (port 3000) is published directly, because Umbrel's app proxy
  fronts a single port per app. Grafana therefore does **not** sit behind
  your Umbrel login: change its admin password on first use and, if you
  expose your Umbrel beyond your home network, put Grafana behind your own
  access control. This is the main design trade-off in this package and is
  called out here rather than hidden.
- PostgreSQL and Mosquitto run as companion containers; their data lives
  under the app's Umbrel data directory, mounted with short-syntax bind
  mounts so Docker creates the directories on first install.
- Grafana starts as root: Umbrel's bind-mounted data directories are
  created owned by root, and Grafana's entrypoint then fixes the data
  directory's ownership to the grafana user and drops privileges. Running
  Grafana as UID 1000 or its image default 472 cannot write to a
  root-owned bind mount and crash-loops (see Troubleshooting).
- The TeslaMate encryption key and the database password are derived on
  the installing device from Umbrel's per-app seed (`exports.sh`). They are
  not in this repository and are never transmitted anywhere.
- All images are pinned by digest for the shipped version (TeslaMate
  4.4.0). Updating to a newer TeslaMate means updating the version in
  `umbrel-app.yml` and the pinned digests in `docker-compose.yml` together.

### Migrating from a standalone TeslaMate install

Installing this app starts with an empty database. If you already run
TeslaMate via plain Docker Compose, migrate your history deliberately —
TeslaMate cannot backfill drives or charges from Tesla's API for periods
it was not logging. The procedure that was used successfully for this
package:

1. Back up first: take a PostgreSQL dump of the old database (for
   example with `pg_dump`) and keep the old stack's compose file, data
   volumes and environment file untouched as a rollback safety net.
2. Stop the old stack (without deleting its volumes).
3. Install this app from the Kooshking store and let it finish, but do
   **not** sign in to the new TeslaMate yet.
4. Stop the new app's `teslamate` container only, so nothing writes to
   its database during the restore.
5. Empty the new database, dropping **both** schemas — `public` and
   TeslaMate's `private` schema, which holds the tokens table. Dropping
   only `public` leaves the old tokens table behind and the restore will
   fail on it (see Troubleshooting).
6. Restore the dump into the new app's database and check it for errors
   and for sensible row counts (cars, drives, charges, positions).
7. Start the new app's `teslamate` container again.
8. **Sign in again with your token app.** Tokens from the old install
   were encrypted under the old install's encryption key, which the new
   app does not share, so TeslaMate will report `not_signed_in` until you
   provide a fresh token pair. This is expected, not a restore failure.
9. Grafana in the new app is fresh: log in with `admin` / `admin`,
   change the password, and re-set TeslaMate Settings → URLs as in
   First run above.

Only once the new app is verified working (car visible, history present,
both UIs serving) should the old volumes be deleted.

### Troubleshooting

- **Install fails with exit code 1.** An early version of this package
  used long-syntax bind mounts with `create_host_path: false`, and Umbrel
  never created the data directories, so Docker refused with "bind source
  path does not exist". The current package uses short-syntax mounts,
  which create the directories automatically. If you hit this on an old
  store copy, remove and re-add the store (or wait for Umbrel to refresh
  its local store copy) and install again.
- **Grafana crash-loops with "GF_PATHS_DATA is not writable".** This was
  the package running Grafana as UID 1000 against a root-owned bind
  mount. The current package starts Grafana as root (see How it is
  wired). If you installed the old version, update the app, or as a
  one-off fix run
  `sudo chown -R 1000:1000 ~/umbrel/app-data/kooshking-teslamate/data/grafana`
  on your Umbrel and let Grafana restart.
- **Grafana does not answer on port 3000 right after install.** Wait.
  First-run migrations take several minutes; Grafana only starts
  listening once they finish. Check the container's logs for
  "HTTP Server Listen" before concluding it is broken.
- **TeslaMate reports `not_signed_in` after a migration.** Expected:
  re-sign in with a fresh token pair (step 8 above). The restored token
  row cannot be decrypted under the new app's key.
- **Uninstalling the app removes its data.** The app's database lives
  under its Umbrel data directory, so uninstalling deletes it. Back up
  with a database dump first if you want to keep your history.

### Status

Verified end to end on 3 November 2026 on the author's Umbrel: a clean
install from the published store via the App Store UI (all four
containers up, database healthy, TeslaMate serving through Umbrel's app
proxy, Grafana serving its login page with no manual fix and no
permission errors), followed by a successful database restore from a
standalone TeslaMate install (1 car, 7 positions) and a fresh token
sign-in. Earlier install attempts on the same day found and fixed the
two issues documented in Troubleshooting (bind-mount creation and
Grafana permissions); both fixes are in the published package.

Published 3 November 2026 at https://github.com/kooshking123/umbrel-app-store.
The app icon is the Model 3 outline logo, uploaded as `icon.png` at the
repository root and referenced from the app manifest.
