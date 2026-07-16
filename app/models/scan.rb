class Scan < ApplicationRecord
  has_many :user_scans, dependent: :destroy
  has_many :users, through: :user_scans

  validates :url, presence: true, uniqueness: true
  validates :content, presence: true

  # TODO(team): ScanAnalyzer's contract (see CLAUDE.md) still emits these 4
  # flat category keys. The design system's Report page groups findings
  # under 4 different, richer categories (Privacy / User Rights / Legal
  # Fairness / Content Ownership), each with multiple sub-findings and a
  # weight. This is a rough 1:1 relabeling of the current keys so the Report
  # page can use the new names today — replace once the ScanAnalyzer prompt
  # is updated to emit the real taxonomy directly.
  CATEGORY_DISPLAY = {
    "data_sharing" => "Privacy",
    "cancellation" => "User Rights",
    "tracking" => "Legal Fairness",
    "ai_training" => "Content Ownership"
  }.freeze

  CATEGORY_ORDER = %w[data_sharing cancellation tracking ai_training].freeze

  # TODO(team): static placeholder weights matching the design system mockup
  # (Privacy 40% / User Rights 25% / Legal Fairness 25% / Content Ownership
  # 10%). Not computed from anything — replace once ScanAnalyzer actually
  # weighs categories.
  CATEGORY_WEIGHT = {
    "data_sharing" => "40% weight",
    "cancellation" => "25% weight",
    "tracking" => "25% weight",
    "ai_training" => "10% weight"
  }.freeze

  def display_categories
    (full_report["categories"] || []).sort_by { |c| CATEGORY_ORDER.index(c["name"]) || 99 }
  end
end
