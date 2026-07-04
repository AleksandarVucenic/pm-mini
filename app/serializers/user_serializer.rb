class UserSerializer
  include JSONAPI::Serializer

  attributes :name, :email

  def self.embedded(user)
    { id: user.id, name: user.name, email: user.email }
  end
end
