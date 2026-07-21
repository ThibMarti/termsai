class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # TODO: replace these homepage stub constants with real @scan-backed data
  # once a featured/example scan is available.
  HERO_SITE = { name: "cloudstream.io", scanned_at: "2 min ago", clause_count: 41 }.freeze

  HERO_FLAGS = [
    { title: "Privacy issues", ref: "§14.2", tone: :risk },
    { title: "User rights", ref: "§14.3", tone: :risk },
    { title: "Legal risks", ref: "§9.1", tone: :caution },
    { title: "Content ownership", ref: "§18.0", tone: :safe }
  ].freeze

  # TODO(team): these 4 categories (Privacy / User Rights / Legal Fairness /
  # Content Ownership) are the design system's canonical breakdown, but
  # CLAUDE.md's ScanAnalyzer contract currently emits different category
  # names (data_sharing / ai_training / tracking / cancellation). Reconcile
  # before wiring this section to real @scan data.
  BREAKDOWN_STATS = [
    { label: "Privacy", value: "High", tone: :risk },
    { label: "User Rights", value: "High", tone: :risk },
    { label: "Legal Fairness", value: "High", tone: :risk },
    { label: "Content Ownership", value: "Medium", tone: :caution }
  ].freeze

  # Shared between the Home teaser and the full Tricks & tips page so the
  # copy only lives in one place.
  SCAN_TIPS = [
    { num: "01", title: "Paste the full text",
      body: "Include every section — truncated documents miss the clauses that matter most, " \
            "like arbitration buried near the end." },
    { num: "02", title: "Add the source URL",
      body: "The site name and URL let terms AI reuse the report and compare against the same service over time." },
    { num: "03", title: "Scan the Privacy Policy too",
      body: "Terms and Privacy are separate documents. The riskiest data-sharing language " \
            "usually lives in the Privacy Policy." },
    { num: "04", title: "Re-scan after updates",
      body: "Services change terms quietly. If you get a \"terms updated\" email, run a fresh scan to see what moved." }
  ].freeze

  CLAUSE_EXAMPLES = [
    { article: "Section 14.2 — Dispute resolution", tone: :risk,
      annotation: "Class action waiver",
      text: "You agree that any dispute will be resolved through binding arbitration and that ",
      mark: "you waive any right to participate in a class action, class arbitration, or representative proceeding",
      suffix: "." },
    { article: "Section 9.1 — License to content", tone: :caution,
      annotation: "Broad content license",
      text: "By posting content, you grant us ",
      mark: "a perpetual, irrevocable, worldwide license to use, modify, and sublicense",
      suffix: " your content for any purpose." },
    { article: "Section 22.4 — Changes to these terms", tone: :risk,
      annotation: "Unilateral changes, no notice",
      text: "We may modify these terms at any time ",
      mark: "without prior notice, and continued use constitutes acceptance",
      suffix: " of the new terms." }
  ].freeze

  def home
    @hide_default_navbar = true

    @hero_score = 3
    @hero_percentile = 82 # "riskier than X% of services"
    @hero_site = HERO_SITE
    @hero_flags = HERO_FLAGS

    @breakdown_score = 3
    @breakdown_stats = BREAKDOWN_STATS

    @clause_examples = CLAUSE_EXAMPLES
  end

  def dashboard
    @hide_default_navbar = true
    @tokens_count = current_user.total_scan_allowance
    @scans_count = current_user.scans.count
    @recent_scans = current_user.scans.order(created_at: :desc).limit(1)
    @news_articles = NewsFeedFetcher.new.call
    @tip_teasers = SCAN_TIPS.first(3)
  end

  def news
    @hide_default_navbar = true
    @articles_by_category = NewsFeedFetcher.new.call_by_category
  end

  def new_scan
    @hide_default_navbar = true
    @scan = Scan.new
    @recent_scans = current_user.scans.order(created_at: :desc).limit(3)
    @tokens_count = current_user.total_scan_allowance
  end

  def scan_history
    @hide_default_navbar = true
    @scans = current_user.scans.order(created_at: :desc)
  end

  def profile
    @hide_default_navbar = true
    @tokens_count = current_user.total_scan_allowance
    @recent_orders = Order.where(user: current_user).includes(:offer).order(created_at: :desc).limit(5)
  end

  def regenerate_extension_token
    current_user.regenerate_extension_token!
    redirect_to profile_path, notice: "Extension token regenerated — update it in the Chrome extension."
  end

  def tricks_and_tips
    @hide_default_navbar = true
    @scan_tips = SCAN_TIPS
  end
end
