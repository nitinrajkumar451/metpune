class JudgingCriterion < ApplicationRecord
  # Set the correct table name
  self.table_name = 'judging_criterions'
  
  # Associations
  belongs_to :hackathon
  
  # Validations
  validates :name, presence: true
  validates :hackathon_id, presence: true
  validates :name, uniqueness: { scope: :hackathon_id, message: "should be unique within a hackathon" }
  validates :weight, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :ordered, -> { order(name: :asc) }

  # Instance Methods
  def to_s
    name
  end
end
