class User < ApplicationRecord
  has_secure_password

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  private
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
