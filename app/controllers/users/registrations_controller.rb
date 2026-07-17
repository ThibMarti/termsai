module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    # Devise::RegistrationsController defines this itself (not via the shared
    # Devise::Controllers::Helpers module), so overriding it on
    # ApplicationController alone doesn't work — it has to live here.
    def after_update_path_for(_resource)
      dashboard_path
    end
  end
end
