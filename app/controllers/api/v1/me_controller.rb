class Api::V1::MeController < Api::V1::BaseController
  skip_after_action :verify_authorized

  def show
    render json: { can_scan: current_user.can_scan? }
  end
end
