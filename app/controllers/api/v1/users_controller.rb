class Api::V1::UsersController < Api::V1::BaseController
  def index
    skip_after_action :verify_authorized, :verify_policy_scoped

    def index
      render json: UserSerializer.new(User.all).serializable_hash
    end
  end
end
