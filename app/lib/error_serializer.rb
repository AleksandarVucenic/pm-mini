class ErrorSerializer
  def self.from_message(message, status:)
    numeric_status = Rack::Utils.status_code(status)
    {
      errors: [
        { status: numeric_status.to_s, title: title_for(numeric_status), detail: message }
      ]
    }
  end

  def self.from_active_record_errors(errors, status: :unprocessable_content)
    numeric_status = Rack::Utils.status_code(status)
    {
      errors: errors.full_messages.map do |detail|
        { status: numeric_status.to_s, title: "Validation Error", detail: detail }
      end
    }
  end

  def self.title_for(numeric_status)
    case numeric_status
    when 401 then "Unauthorized"
    when 403 then "Forbidden"
    when 404 then "Not Found"
    when 422 then "Validation Error"
    when 429 then "Too Many Requests"
    else "Error"
    end
  end
end
