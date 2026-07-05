class Api::V1::UsersController < Api::V1::BaseController
  skip_after_action :verify_authorized, :verify_policy_scoped

  def index
    pagy, users = paginate(User.all)
    render json: UserSerializer.new(users, meta: pagination_meta(pagy)).serializable_hash
  end
end
