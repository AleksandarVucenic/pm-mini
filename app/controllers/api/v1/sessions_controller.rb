class Api::V1::SessionsController < Devise::SessionsController
  rate_limit to: 5, within: 3.minutes, only: :create,
             by: -> { "#{request.ip}:#{params.dig(:user, :email).to_s.downcase}" },
             with: -> { render json: ErrorSerializer.from_message("Too many login attempts. Please try again later.", status: :too_many_requests), status: :too_many_requests }

  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: UserSerializer.new(resource).serializable_hash, status: :ok
  end

  def respond_to_on_destroy(*)
    if current_user
      render json: { data: { message: "Logged out successfully" } }, status: :ok
    else
      render json: ErrorSerializer.from_message("Not logged in", status: :unauthorized), status: :unauthorized
    end
  end
end
