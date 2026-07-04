class ApiFailureApp < Devise::FailureApp
  def respond
    self.status = 401
    self.content_type = "application/json"
    self.response_body = ErrorSerializer.from_message(i18n_message, status: :unauthorized).to_json
  end
end
