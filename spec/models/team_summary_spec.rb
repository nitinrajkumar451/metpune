require 'rails_helper'

RSpec.describe TeamSummary, type: :model do
  # Validations
  it { should validate_presence_of(:team_name) }
  it { should validate_uniqueness_of(:team_name) }
  it { should validate_inclusion_of(:status).in_array(%w[pending processing success failed]) }

  # Scopes
  describe 'scopes' do
    let!(:pending_summary) { create(:team_summary, :pending) }
    let!(:processing_summary) { create(:team_summary, :processing) }
    let!(:success_summary) { create(:team_summary) }
    let!(:failed_summary) { create(:team_summary, :failed) }

    it 'returns pending summaries' do
      expect(TeamSummary.pending).to include(pending_summary)
      expect(TeamSummary.pending).not_to include(success_summary)
    end

    it 'returns processing summaries' do
      expect(TeamSummary.processing).to include(processing_summary)
      expect(TeamSummary.processing).not_to include(success_summary)
    end

    it 'returns successful summaries' do
      expect(TeamSummary.success).to include(success_summary)
      expect(TeamSummary.success).not_to include(failed_summary)
    end

    it 'returns failed summaries' do
      expect(TeamSummary.failed).to include(failed_summary)
      expect(TeamSummary.failed).not_to include(success_summary)
    end
  end
end
