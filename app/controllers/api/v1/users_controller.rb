class Api::V1::UsersController < Api::V1::BaseController
  def index
    success(data: User.all.map { |user| UserSerializer.call(user) })
  end
end
