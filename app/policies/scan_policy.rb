# frozen_string_literal: true

class ScanPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    true
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
