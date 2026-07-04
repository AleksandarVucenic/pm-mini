class Api::V1::UsersController < Api::V1::BaseController
  def index
    render json: UserSerializer.new(User.all).serializable_hash
  end
end
