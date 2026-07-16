class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # TODO: replace these homepage stub constants with real @scan-backed data
  # once a featured/example scan is available.
  HERO_SITE = { name: "cloudstream.io", scanned_at: "2 min ago", clause_count: 41 }.freeze

  HERO_FLAGS = [
    { title: "Privacy issues", ref: "§14.2", tone: :risk },
    { title: "Forced arbitration", ref: "§14.3", tone: :risk },
    { title: "Broad content license", ref: "§9.1", tone: :caution },
    { title: "Clear data deletion policy", ref: "§18.0", tone: :safe }
  ].freeze

  BREAKDOWN_STATS = [
    { label: "Arbitration", value: "Forced", tone: :risk },
    { label: "Class action", value: "Waived", tone: :risk },
    { label: "Data sharing", value: "Broad", tone: :caution },
    { label: "Termination", value: "Fair", tone: :safe }
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

    @hero_score = 3.0
    @hero_percentile = 82 # "riskier than X% of services"
    @hero_site = HERO_SITE
    @hero_flags = HERO_FLAGS

    @breakdown_score = 2.6
    @breakdown_stats = BREAKDOWN_STATS

    @clause_examples = CLAUSE_EXAMPLES
  end

  def dashboard
    @scans = current_user.scans.order(created_at: :desc)
    @tokens_count = current_user.total_scan_allowance
  end
end
