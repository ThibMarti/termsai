class Api::V1::ScansController < Api::V1::BaseController
  def create
    result = ScanCreation.new(user: current_user, scan_params: scan_params, authorizer: method(:authorize)).call
    payload, status = response_for(result)
    render json: payload, status: status
  end

  private

  def response_for(result)
    case result.status
    when :blocked then [{ error: result.message }, :payment_required]
    when :invalid then [{ error: result.message }, :unprocessable_entity]
    when :reused then [scan_payload(result.scan), :ok]
    when :created then [scan_payload(result.scan), :created]
    end
  end

  def scan_params
    params.require(:scan).permit(:site_name, :url, :content)
  end

  def scan_payload(scan)
    {
      id: scan.id, site_name: scan.site_name, url: scan.url,
      risk_score: scan.risk_score, full_report: scan.full_report
    }
  end
end
