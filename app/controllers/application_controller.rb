class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:test_data]

  before_action :configure_permitted_parameters, if: :devise_controller?

  def test_data
    render json: {
      users: User.all,
      credits: Credit.all,
      documents: Document.all,
      scan_results: ScanResult.all,
      scans: Scan.all,
      user_scans: UserScan.all
    }
  end

  protected

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])

    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
  end
end
