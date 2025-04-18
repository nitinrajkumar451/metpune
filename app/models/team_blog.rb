class TeamBlog < ApplicationRecord
  # Validations
  validates :team_name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending processing success failed] }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :success, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
end
