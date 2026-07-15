# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def show?
    user.admin?
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

  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.where(user: user)
    end
  end
end
