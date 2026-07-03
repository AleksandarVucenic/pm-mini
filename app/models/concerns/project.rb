class Project < ApplicationRecord
  belongs_to :pm, class_name: "User"

  validates :name, presence: true, length: { maximum: 150 }
end