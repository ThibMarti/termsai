class ScanController < ApplicationController
  def show
    @scan = Scan.find(params[:id])
    authorize @scan
  end

  def create
    @scan = Scan.find_or_create_by(url: scan_params[:url])
    authorize @scan

    user_scan = UserScan.find_or_initialize_by(user: current_user, scan: @scan)
    authorize user_scan
    user_scan.save

    redirect_to @scan
  end

  private

  def scan_params
    params.require(:scan).permit(:url)
  end
end
