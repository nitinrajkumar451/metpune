require 'rails_helper'

RSpec.describe TeamEvaluation, type: :model do
  # Validations
  it { should validate_presence_of(:team_name) }
  it { should validate_presence_of(:scores) }
  it { should validate_inclusion_of(:status).in_array(%w[pending processing success failed]) }

  # Uniqueness validation test
  describe 'uniqueness validations' do
    before { create(:team_evaluation, team_name: "Unique Team") }

    it "validates uniqueness of team_name" do
      duplicate = build(:team_evaluation, team_name: "Unique Team")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:team_name]).to include("has already been taken")
    end
  end

  # Factory
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:team_evaluation)).to be_valid
    end

    it 'has valid trait factories' do
      expect(build(:team_evaluation, :pending)).to be_valid
      expect(build(:team_evaluation, :processing)).to be_valid
      expect(build(:team_evaluation, :failed)).to be_valid
      expect(build(:team_evaluation, :high_score)).to be_valid
      expect(build(:team_evaluation, :low_score)).to be_valid
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:pending_eval) { create(:team_evaluation, :pending, team_name: "PendingTeam") }
    let!(:processing_eval) { create(:team_evaluation, :processing, team_name: "ProcessingTeam") }
    let!(:success_eval) { create(:team_evaluation, team_name: "SuccessTeam") }
    let!(:failed_eval) { create(:team_evaluation, :failed, team_name: "FailedTeam") }
    let!(:high_score_eval) { create(:team_evaluation, :high_score, team_name: "HighScoreTeam") }
    let!(:low_score_eval) { create(:team_evaluation, :low_score, team_name: "LowScoreTeam") }

    it 'pending returns only pending evaluations' do
      expect(TeamEvaluation.pending).to contain_exactly(pending_eval)
    end

    it 'processing returns only processing evaluations' do
      expect(TeamEvaluation.processing).to contain_exactly(processing_eval)
    end

    it 'success returns only success evaluations' do
      expect(TeamEvaluation.success).to contain_exactly(success_eval, high_score_eval, low_score_eval)
    end

    it 'failed returns only failed evaluations' do
      expect(TeamEvaluation.failed).to contain_exactly(failed_eval)
    end

    it 'ordered_by_score returns evaluations ordered by score' do
      ordered_evals = TeamEvaluation.ordered_by_score.to_a

      # Get only the team names we created for this test
      test_teams = ordered_evals.select { |e|
        [ "HighScoreTeam", "SuccessTeam", "LowScoreTeam" ].include?(e.team_name)
      }

      # Verify these teams are in the right order
      expect(test_teams.map(&:team_name)).to eq([ "HighScoreTeam", "SuccessTeam", "LowScoreTeam" ])
    end
  end

  # Callbacks
  describe 'callbacks' do
    describe '#calculate_total_score' do
      it 'calculates the weighted average of scores' do
        evaluation = build(:team_evaluation,
          scores: {
            "Criterion1" => { "score" => 4.0, "weight" => 2.0 },
            "Criterion2" => { "score" => 5.0, "weight" => 3.0 }
          },
          total_score: nil
        )

        # (4.0 * 2.0 + 5.0 * 3.0) / (2.0 + 3.0) = (8.0 + 15.0) / 5.0 = 23.0 / 5.0 = 4.6
        evaluation.save
        expect(evaluation.total_score).to eq(4.6)
      end

      it 'does nothing if scores are blank' do
        evaluation = build(:team_evaluation, scores: {}, total_score: nil)
        evaluation.save
        expect(evaluation.total_score).to be_nil
      end
    end
  end
end
