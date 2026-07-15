module ApplicationHelper
  def risk_badge_class(score)
    case score.to_i
    when 8..10 then "bg-success"
    when 5..7  then "bg-warning"
    else            "bg-danger"
    end
  end

  TONE_CLASSES = { risk: "bg-danger", caution: "bg-warning", safe: "bg-success" }.freeze

  def tone_class(tone)
    TONE_CLASSES[tone.to_sym]
  end

  def signup_cta_path
    user_signed_in? ? dashboard_path : new_user_registration_path
  end

  def signup_cta_label(signed_out_label)
    user_signed_in? ? "Go to dashboard" : signed_out_label
  end
end
