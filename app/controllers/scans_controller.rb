class ScansController < ApplicationController
  rescue_from RubyLLM::Error do
    redirect_to new_scan_path, alert: "The analysis failed — please try again. Nothing was charged."
  end

  def create
    result = ScanCreation.new(user: current_user, scan_params: scan_params, authorizer: method(:authorize)).call

    case result.status
    when :blocked, :invalid
      redirect_to new_scan_path, alert: result.message
    when :created
      redirect_to scan_path(result.scan), notice: "Scan complete."
    when :reused
      redirect_to scan_path(result.scan), notice: "This site was already scanned, here's the existing report."
    end
  end

  def show
    @scan = current_user.scans.find(params[:id])
    authorize @scan
    @hide_default_navbar = true
    @verdict = build_verdict(@scan)
    @groups = build_groups(@scan)
  end

  private

  def build_groups(scan)
    scan.display_categories.map do |category|
      {
        name: Scan::CATEGORY_DISPLAY[category["name"]] || category["name"].humanize,
        weight: Scan::CATEGORY_WEIGHT[category["name"]],
        level: category["level"].humanize,
        tone: helpers.risk_tone_for_level(category["level"]),
        items: (category["items"] || []).map do |item|
          {
            label: item["label"],
            finding: item["finding"],
            dot: helpers.risk_tone_for_level(item["level"]),
            article: item["article"],
            quote: item["quote"]
          }
        end
      }
    end
  end

  def build_verdict(scan)
    tone = helpers.risk_tone(scan.risk_score)
    names_at = ->(level) { scan.display_categories.select { |c| c["level"] == level }
                                                   .map { |c| Scan::CATEGORY_DISPLAY[c["name"]] }.compact }
    high = names_at.call("high")
    medium = names_at.call("medium")

    sentence =
      if high.any?
        "#{high.to_sentence} #{high.one? ? "scores" : "score"} poorly. Read the flagged clauses below before accepting."
      elsif medium.any?
        "#{medium.to_sentence} #{medium.one? ? "needs" : "need"} a closer look. Read the flagged clauses below before accepting."
      else
        "No category scored poorly on this document. Still worth a quick read of the flagged clauses below."
      end

    label = { safe: "Recommended", caution: "Proceed with caution", risk: "Not recommended" }[tone]
    { tone: tone, label: label, sentence: sentence }
  end

  def scan_params
    params.require(:scan).permit(:site_name, :url, :content)
  end
end
