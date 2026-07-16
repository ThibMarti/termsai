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

  def signup_cta_path
    user_signed_in? ? new_scan_path : new_user_registration_path
  end

  def signup_cta_label(signed_out_label)
    user_signed_in? ? "Go to your scans" : signed_out_label
  end

  def user_initials(user)
    [user.first_name, user.last_name].compact.map { |n| n[0] }.join.upcase
  end
end
