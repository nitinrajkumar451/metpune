class HackathonInsight < ApplicationRecord
  # Associations
  belongs_to :hackathon

  # Validations
  validates :hackathon_id, presence: true
  validates :status, inclusion: { in: %w[pending processing success failed] }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :success, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }

  # Get the latest insights
  scope :latest, -> { order(created_at: :desc) }
end
