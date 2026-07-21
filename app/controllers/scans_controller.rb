class ScansController < ApplicationController
  def create
    existing_scan = Scan.find_by(url: scan_params[:url])
    return reuse_existing_scan(existing_scan) if existing_scan

    @scan = Scan.new(scan_params)
    @scan.status = "processing" if @scan.respond_to?(:status=)
    authorize @scan

    return redirect_to new_scan_path, alert: "No tokens left." unless current_user.can_scan?

    if @scan.save
      register_scan_for(current_user)
      ScanAnalysisJob.perform_later(@scan)
      redirect_to scan_path(@scan)
    else
      redirect_to new_scan_path, alert: @scan.errors.full_messages.to_sentence
    end
  end

  def show
    @scan = current_user.scans.find(params[:id])
    authorize @scan
    @hide_default_navbar = true
    @verdict = @scan.verdict
    @groups = @scan.groups
  end

  private

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
