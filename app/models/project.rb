class Project < ApplicationRecord
  belongs_to :pm, class_name: "User", inverse_of: :managed_projects
  has_many :tasks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 150 }
end
