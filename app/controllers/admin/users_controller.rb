class Admin::UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[edit update destroy]

  def index
    @hide_default_navbar = true
    @users = User.order(:first_name, :last_name)
    if params[:q].present?
      q = "%#{params[:q]}%"
      @users = @users.where("email ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q", q: q)
    end
  end

  def edit
    @hide_default_navbar = true
  end

  def update
    if params[:adjustment].present?
      amount = params[:adjustment].to_i
      @user.tokens.create!(token_amount: amount) unless amount.zero?
      redirect_to edit_admin_user_path(@user), notice: "Adjusted #{@user.first_name}'s balance by #{amount} tokens." and return
    end

    if @user.update(user_params)
      redirect_to admin_users_path, notice: "#{@user.first_name} updated."
    else
      @hide_default_navbar = true
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You can't delete your own account from here."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "#{@user.first_name} #{@user.last_name} deleted."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.fetch(:user, {}).permit(:first_name, :last_name, :email, :admin)
  end

  def require_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
  end
end
