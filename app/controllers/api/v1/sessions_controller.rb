class Api::V1::SessionsController < Devise::SessionsController
  include Response
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    success(data: {user: UserSerializer.call(resource)}, message: "Logged in successfully", status: :ok)
  end

  def respond_to_on_destroy(*)
    if current_user
      success(data: nil, message: "Logged out successfully", status: :ok)
    else
      unauthorized(message: "Not logged in")
    end
  end
end
