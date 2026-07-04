class Api::V1::BaseController < ApplicationController
  include Pundit::Authorization
  include Paginatable

  before_action :authenticate_user!
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: ErrorSerializer.from_message(e.message, status: :not_found), status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: ErrorSerializer.from_active_record_errors(e.record.errors), status: :unprocessable_content
  end

  rescue_from ActiveRecord::InvalidForeignKey do |e|
    render json: ErrorSerializer.from_message("Cannot delete this record because it is referenced elsewhere", status: :unprocessable_content), status: :unprocessable_content
  end

  rescue_from Pundit::NotAuthorizedError do
    render json: ErrorSerializer.from_message("You are not authorized to perform this action", status: :forbidden), status: :forbidden
  end
end
