class JudgingCriterion < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :weight, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :ordered, -> { order(name: :asc) }

  # Instance Methods
  def to_s
    name
  end
end
