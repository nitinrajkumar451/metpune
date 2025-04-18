class TeamEvaluation < ApplicationRecord
  # Validations
  validates :team_name, presence: true, uniqueness: true
  validates :scores, presence: true
  validates :status, inclusion: { in: %w[pending processing success failed] }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :success, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :ordered_by_score, -> { where.not(total_score: nil).order(total_score: :desc) }

  # Callbacks
  before_save :calculate_total_score

  private

  def calculate_total_score
    return if scores.blank?

    # Calculate weighted average of scores
    weighted_scores = []
    total_weight = 0

    scores.each do |criterion_name, score_data|
      weight = score_data["weight"] || 1.0
      score = score_data["score"] || 0

      weighted_scores << score.to_f * weight.to_f
      total_weight += weight.to_f
    end

    if total_weight > 0
      self.total_score = (weighted_scores.sum / total_weight).round(2)
    else
      self.total_score = nil
    end
  end
end
