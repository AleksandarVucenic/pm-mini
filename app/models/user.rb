class User < ApplicationRecord
  devise :database_authenticatable, :validatable, :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  has_many :managed_projects, class_name: "Project", foreign_key: :pm_id, dependent: :restrict_with_error, inverse_of: :pm
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
end
