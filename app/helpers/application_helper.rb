module ApplicationHelper
  def risk_badge_class(score)
    case score.to_i
    when 8..10 then "bg-success"
    when 5..7  then "bg-warning"
    else            "bg-danger"
    end
  end
end
