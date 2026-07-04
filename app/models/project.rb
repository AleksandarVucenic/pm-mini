class Project < ApplicationRecord
  belongs_to :pm, class_name: "User"
  has_many :tasks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 150 }
end
