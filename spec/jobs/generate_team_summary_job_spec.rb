require 'rails_helper'

RSpec.describe GenerateTeamSummaryJob, type: :job do
  include ActiveJob::TestHelper

  let(:team_name) { "TestTeam" }
  let(:mock_client) { instance_double(Ai::Client) }
  let(:summary_content) { "# Team TestTeam Report\n\n## PRODUCT OBJECTIVE\nTest team is working on..." }

  before do
    allow(Ai::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:generate_team_summary).and_return(summary_content)
  end

  describe "#perform" do
    context "with successful submissions" do
      let!(:submissions) { create_list(:submission, 3, :success, team_name: team_name) }

      it "creates a team summary with status 'success'" do
        expect {
          GenerateTeamSummaryJob.perform_now(team_name)
        }.to change { TeamSummary.count }.by(1)

        team_summary = TeamSummary.find_by(team_name: team_name)
        expect(team_summary.status).to eq("success")
        expect(team_summary.content).to eq(summary_content)
      end

      it "calls the AI client to generate the summary" do
        expect(mock_client).to receive(:generate_team_summary).with(
          team_name,
          an_instance_of(Array)
        )

        GenerateTeamSummaryJob.perform_now(team_name)
      end
    end

    context "with no submissions" do
      it "creates a team summary with status 'failed'" do
        expect {
          GenerateTeamSummaryJob.perform_now(team_name)
        }.to change { TeamSummary.count }.by(1)

        team_summary = TeamSummary.find_by(team_name: team_name)
        expect(team_summary.status).to eq("failed")
        expect(team_summary.content).to include("No successful submissions found")
      end
    end

    context "when the AI client fails" do
      let!(:submissions) { create_list(:submission, 3, :success, team_name: team_name) }

      before do
        allow(mock_client).to receive(:generate_team_summary).and_raise(StandardError.new("API error"))
      end

      it "creates a team summary with status 'failed'" do
        expect {
          GenerateTeamSummaryJob.perform_now(team_name)
        }.to change { TeamSummary.count }.by(1)

        team_summary = TeamSummary.find_by(team_name: team_name)
        expect(team_summary.status).to eq("failed")
        expect(team_summary.content).to include("Error:")
      end
    end
  end
end
