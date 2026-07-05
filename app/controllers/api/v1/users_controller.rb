class Api::V1::UsersController < Api::V1::BaseController
  def index
    pagy, users = paginate(policy_scope(User))
    render json: UserSerializer.new(users, meta: pagination_meta(pagy)).serializable_hash
  end
end
