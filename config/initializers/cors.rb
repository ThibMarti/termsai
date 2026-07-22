# Lets the TermsAI Chrome extension (chrome-extension://<id> origin) call
# the JSON API under /api/*. Scoped to /api/* only — normal browser
# HTML/Turbo traffic never passes through this middleware.
#
# CHROME_EXTENSION_ORIGINS is a comma-separated list of allowed origins, e.g.
#   CHROME_EXTENSION_ORIGINS=chrome-extension://abcdefghijklmnopqrstuvwxyzabcdef
# Get the real ID from chrome://extensions after "Load unpacked" (see
# extension/README.md). Each teammate's local unpacked install gets a
# DIFFERENT auto-generated ID unless the manifest pins a `key` field — that's
# a future robustness improvement, not needed for the bootcamp deadline.
allowed_origins = ENV.fetch("CHROME_EXTENSION_ORIGINS", "").split(",").map(&:strip)
# "null" never matches a real Origin header — keeps Rack::Cors happy if unset.
allowed_origins = ["null"] if allowed_origins.empty?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    # No cookies involved — the extension authenticates with a bearer
    # token (Authorization header), not a session, so credentials: true
    # isn't needed here.
    resource "/api/*", headers: :any, methods: %i[get post options]
  end
end
