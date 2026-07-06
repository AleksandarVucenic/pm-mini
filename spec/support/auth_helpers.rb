module AuthHelpers
  def auth_headers(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
    { "Authorization" => response.headers["Authorization"] }
  end
end
