module Api
  module V1
    class BaseController < ApplicationController
      include Response
      include Pundit::Authorization

      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: e.message }, status: :not_found
      end

      rescue_from Pundit::NotAuthorizedError do
        render json: { error: "You are not authorized to perform this action" }, status: :forbidden
      end
    end
  end
end
