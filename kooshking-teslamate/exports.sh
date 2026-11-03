# Secrets for the TeslaMate Umbrel app, derived from Umbrel's per-app seed.
# Nothing secret is stored in this repository: these values are generated on
# the installing Umbrel device and never leave it.
export APP_KOOSHKING_TESLAMATE_ENCRYPTION_KEY="$(derive_entropy "env-${app_entropy_identifier}-ENCRYPTION_KEY" | head -c64)"
export APP_KOOSHKING_TESLAMATE_DATABASE_PASS="$(derive_entropy "env-${app_entropy_identifier}-DATABASE_PASS" | head -c64)"
