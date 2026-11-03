# Kooshking Umbrel Community App Store

A community Umbrel app store. It currently ships one app:

## TeslaMate (`kooshking-teslamate`)

TeslaMate is a self-hosted data logger for Tesla vehicles: it records drives,
charges, state changes and positions into PostgreSQL and ships Grafana
dashboards for efficiency, battery degradation, charging cost and vampire
drain. This repository only *packages* TeslaMate for Umbrel; TeslaMate itself
is by teslamate-org and is licensed AGPL-3.0
(see https://github.com/teslamate-org/teslamate).

### Add this store to Umbrel

1. Open the **App Store** in umbrelOS.
2. Click the **⋯** menu (top right) → **Community App Stores**.
3. Add the store URL (the public GitHub URL of this repository once published).
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
4. In TeslaMate, go to Settings → URLs and set the Web App and Dashboards
   URLs to the addresses you use to reach them, so the links between
   TeslaMate and Grafana work.

### How it is wired (draft)

- TeslaMate (port 4000) is fronted by Umbrel's `app_proxy`.
- Grafana (port 3000) is published directly, because Umbrel's app proxy
  fronts a single port per app. Grafana therefore does **not** sit behind
  your Umbrel login: change its admin password on first use and, if you
  expose your Umbrel beyond your home network, put Grafana behind your own
  access control. This is the main design trade-off in this draft and is
  called out here rather than hidden.
- PostgreSQL and Mosquitto run as companion containers; their data lives
  under the app's Umbrel data directory.
- The TeslaMate encryption key and the database password are derived on
  the installing device from Umbrel's per-app seed (`exports.sh`). They are
  not in this repository and are never transmitted anywhere.
- All images are pinned by digest for the shipped version (TeslaMate
  4.4.0). Updating to a newer TeslaMate means updating the version in
  `umbrel-app.yml` and the pinned digests in `docker-compose.yml` together.

### Migrating from a standalone TeslaMate install

Installing this app starts with an empty database. If you already run
TeslaMate via plain Docker Compose, do not expect your history to appear:
migrate it deliberately with a PostgreSQL dump from the old database and a
restore into the app's database, and back up first. TeslaMate cannot
backfill drives or charges from Tesla's API for periods it was not logging.

### Status

Draft, built 3 November 2026. The stack was test-run on the author's
Umbrel as a separate compose project (test ports 4001/3001, separate
data directory, live TeslaMate stack untouched): TeslaMate served its
fresh sign-in page and Grafana served its login page, then the test
stack and its data were removed. One test finding is already in the
package: Grafana must run as UID 1000, not its image default 472, or it
cannot write to Umbrel's bind-mounted data directory. The icon is a
placeholder and should be replaced with the TeslaMate project logo
before the store is shared publicly.

Not yet published: a full Umbrel-managed install (via the App Store UI,
with Umbrel's app proxy in front of TeslaMate) still needs the store to
be published to a public GitHub repository first, so that Umbrel can add
it as a community app store.
