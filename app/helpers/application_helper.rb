module ApplicationHelper
  def risk_badge_class(score)
    case score.to_i
    when 8..10 then "bg-success"
    when 5..7  then "bg-warning"
    else            "bg-danger"
    end
  end

  def risk_tone(score)
    case score.to_i
    when 8..10 then :safe
    when 5..7  then :caution
    else            :risk
    end
  end

  def risk_label(score)
    case score.to_i
    when 8..10 then "Low risk"
    when 5..7  then "Medium risk"
    else            "High risk"
    end
  end

  LEVEL_TONES = { "low" => :safe, "medium" => :caution, "high" => :risk }.freeze

  def risk_tone_for_level(level)
    LEVEL_TONES[level.to_s] || :safe
  end

  TONE_CLASSES = { risk: "bg-danger", caution: "bg-warning", safe: "bg-success" }.freeze

  def tone_class(tone)
    TONE_CLASSES[tone.to_sym]
  end

  # Distinct from tone_class: Bootstrap's bg-* utilities set background-color
  # with !important, which would always beat our tinted badge styling
  # regardless of selector specificity. This returns our own classes instead.
  TONE_BADGE_CLASSES = { risk: "tone-badge--risk", caution: "tone-badge--caution", safe: "tone-badge--safe", info: "tone-badge--info" }.freeze

  def tone_badge_class(tone)
    TONE_BADGE_CLASSES[tone.to_sym]
  end

  def signup_cta_path
    user_signed_in? ? dashboard_path : new_user_registration_path
  end

  def signup_cta_label(signed_out_label)
    user_signed_in? ? "Go to your dashboard" : signed_out_label
  end

  NEWS_CATEGORY_LABELS = {
    data_breach: "Data breach",
    ai_advancement: "AI advancement",
    data_policy: "Data policy"
  }.freeze

  def news_category_label(category)
    NEWS_CATEGORY_LABELS[category.to_sym] || category.to_s.humanize
  end

  NEWS_CATEGORY_TONES = { data_breach: :risk, ai_advancement: :info, data_policy: :caution }.freeze

  def news_category_tone(category)
    NEWS_CATEGORY_TONES[category.to_sym] || :info
  end
end
