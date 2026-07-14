# frozen_string_literal: true

class UserScanPolicy < ApplicationPolicy
  def create?
    true
  end

  def destroy?
    record.user == user
  end
end
