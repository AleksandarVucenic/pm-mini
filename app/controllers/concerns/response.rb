module Response
  extend ActiveSupport::Concern

  private

  def success(data: nil, message: "Success", status: :ok)
    response_data = {
      success: true,
      message: message,
    }

    response_data[:data] = data if data

    render json: response_data, status: status
  end

  def error(message: "Error", status: :bad_request, errors: nil)
    render json: {
      success: false,
      message: message,
      errors: errors
    }, status: status
  end

  def created(data: nil, message: "Created successfully")
    success(data: data, message: message, status: :created)
  end

  def updated(data: nil, message: "Updated successfully")
    success(data: data, message: message, status: :ok)
  end

  def deleted(message: "Deleted successfully")
    success(data: nil, message: message, status: :ok)
  end

  def unauthorized(message: "Unauthorized")
    error(message: message, status: :unauthorized)
  end

  def forbidden(message: "Forbidden")
    error(message: message, status: :forbidden)
  end

  def not_found(message: "Not found")
    error(message: message, status: :not_found)
  end

  def validation_error(errors, message: "Validation failed")
    error(message: message, status: :unprocessable_entity, errors: errors)
  end

  def server_error(message: "Internal server error")
    error(message: message, status: :internal_server_error)
  end
end
