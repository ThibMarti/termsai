class Scan < ApplicationRecord
  has_many :user_scans, dependent: :destroy
  has_many :users, through: :user_scans

  validates :url, presence: true, uniqueness: true
  validates :content, presence: true

  CATEGORY_DISPLAY = {
    "data_sharing" => "Privacy",
    "cancellation" => "User Rights",
    "tracking" => "Legal Fairness",
    "ai_training" => "Content Ownership"
  }.freeze

  CATEGORY_ORDER = %w[data_sharing cancellation tracking ai_training].freeze

  CATEGORY_WEIGHT = {
    "data_sharing" => "40% weight",
    "cancellation" => "25% weight",
    "tracking" => "25% weight",
    "ai_training" => "10% weight"
  }.freeze

  def display_categories
    (full_report["categories"] || []).sort_by { |c| CATEGORY_ORDER.index(c["name"]) || 99 }
  end

  def append_content!(chunk)
    new_content = (content || "") + chunk
    update_columns(content: new_content)
  end

  def verdict
    return { tone: :caution, label: "Analyzing...", sentence: "Analysis in progress." } if full_report.blank?

    tone = ApplicationController.helpers.risk_tone(risk_score)
    names_at = lambda { |level|
      display_categories.select { |c| c["level"] == level }
                        .map { |c| CATEGORY_DISPLAY[c["name"]] }.compact
    }
    high = names_at.call("high")
    medium = names_at.call("medium")

    sentence =
      if high.any?
        "#{high.to_sentence} #{high.one? ? 'scores' : 'score'} poorly. Read the flagged clauses below before accepting."
      elsif medium.any?
        "#{medium.to_sentence} #{medium.one? ? 'needs' : 'need'} a closer look. Read the flagged clauses below before accepting."
      else
        "No category scored poorly on this document. Still worth a quick read of the flagged clauses below."
      end

    label = { safe: "Recommended", caution: "Proceed with caution", risk: "Not recommended" }[tone]
    { tone: tone, label: label, sentence: sentence }
  end

  def groups
    return [] if full_report.blank?

    display_categories.map do |category|
      {
        name: CATEGORY_DISPLAY[category["name"]] || category["name"].humanize,
        weight: CATEGORY_WEIGHT[category["name"]],
        level: category["level"].humanize,
        tone: ApplicationController.helpers.risk_tone_for_level(category["level"]),
        items: (category["items"] || []).map do |item|
          {
            label: item["label"],
            finding: item["finding"],
            dot: ApplicationController.helpers.risk_tone_for_level(item["level"]),
            article: item["article"],
            quote: item["quote"]
          }
        end
      }
    end
  end

  def broadcast_completion!
    broadcast_replace_to(
      "scan_#{id}",
      target: "scan_content",
      partial: "scans/frame",
      locals: { scan: self, verdict: verdict, groups: groups }
    )
  end
end
