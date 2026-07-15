class ScansController < ApplicationController
  rescue_from RubyLLM::Error do
    redirect_to new_scan_path, alert: "The analysis failed — please try again. Nothing was charged."
  end

  def new
    @scan = Scan.new
    authorize @scan
  end

  def create
    @scan = Scan.new(scan_params)
    authorize @scan

    return redirect_to dashboard_path, alert: "No tokens or credits left." unless current_user.can_scan?

    report = ScanAnalyzer.new(@scan.content).call
    @scan.assign_attributes(full_report: report, risk_score: report["risk_score"])

    if @scan.save
      register_scan_for(current_user)
      redirect_to scan_path(@scan), notice: "Scan complete."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @scan = current_user.scans.find(params[:id])
    authorize @scan
  end

  private

  def scan_params
    params.require(:scan).permit(:site_name, :url, :content)
  end

  def register_scan_for(user)
    user_scan = user.user_scans.new(scan: @scan)
    authorize user_scan
    user_scan.save!
    user.consume_scan_allowance!
  end
end
