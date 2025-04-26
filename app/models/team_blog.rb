class TeamBlog < ApplicationRecord
  # Associations
  belongs_to :hackathon
  
  # Validations
  validates :team_name, presence: true
  validates :hackathon_id, presence: true
  validates :team_name, uniqueness: { scope: :hackathon_id, message: "should be unique within a hackathon" }
  validates :status, inclusion: { in: %w[pending processing success failed] }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :success, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
end
