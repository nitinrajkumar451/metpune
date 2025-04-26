class Hackathon < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active completed archived] }
  
  # Associations
  has_many :submissions, dependent: :destroy
  has_many :team_summaries, dependent: :destroy
  has_many :team_evaluations, dependent: :destroy
  has_many :team_blogs, dependent: :destroy
  has_many :hackathon_insights, dependent: :destroy
  has_many :judging_criteria, class_name: 'JudgingCriterion', dependent: :destroy
  
  # Scopes
  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }
  scope :archived, -> { where(status: "archived") }
  
  # Methods
  def self.default
    find_by(name: "Metathon 2025") || first
  end
end
