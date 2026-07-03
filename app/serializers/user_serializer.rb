class UserSerializer
  def self.call(user)
    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end
end
