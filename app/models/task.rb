class Task < ApplicationRecord
  belongs_to :project
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, { open: 0, closed: 1 }

  validates :title, presence: true, length: { maximum: 200 }
end
