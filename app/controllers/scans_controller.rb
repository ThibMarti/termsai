class ScansController < ApplicationController
  rescue_from RubyLLM::Error do
    redirect_to new_scan_path, alert: "The analysis failed — please try again. Nothing was charged."
  end

  def new
    @scan = Scan.new
    authorize @scan
  end

  def create
    existing_scan = Scan.find_by(url: scan_params[:url])
    return reuse_existing_scan(existing_scan) if existing_scan

    @scan = Scan.new(scan_params)
    authorize @scan

    return redirect_to dashboard_path, alert: "No tokens left." unless current_user.can_scan?

    analyze_and_save_scan
  end

  def show
    @scan = current_user.scans.find(params[:id])
    authorize @scan
  end

  private

  def analyze_and_save_scan
    report = ScanAnalyzer.new(@scan.content).call
    @scan.assign_attributes(full_report: report, risk_score: report["risk_score"])

    if @scan.save
      register_scan_for(current_user)
      redirect_to scan_path(@scan), notice: "Scan complete."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # This site was already scanned (by anyone) — reuse the existing report
  # instead of burning the user's token on a duplicate AI call.
  def reuse_existing_scan(scan)
    authorize scan
    current_user.user_scans.find_or_create_by!(scan: scan)
    redirect_to scan_path(scan), notice: "This site was already scanned, here's the existing report."
  end

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
