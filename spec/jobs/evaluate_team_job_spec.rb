require 'rails_helper'

RSpec.describe EvaluateTeamJob, type: :job do
  include ActiveJob::TestHelper

  let(:team_name) { "TestTeam" }
  let(:criteria_ids) { [ 1, 2, 3 ] }
  let(:mock_client) { instance_double(Ai::Client) }
  let(:team_summary) { create(:team_summary, team_name: team_name) }
  let(:evaluation_json) {
    {
      "scores" => {
        "Innovation" => { "score" => 4.2, "weight" => 3.0, "feedback" => "Great innovation" },
        "Technical" => { "score" => 4.5, "weight" => 4.0, "feedback" => "Solid technical implementation" }
      },
      "total_score" => 4.37,
      "comments" => "Overall great job"
    }.to_json
  }

  before do
    allow(Ai::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:evaluate_team).and_return(evaluation_json)
  end

  describe "#perform" do
    context "with a successful team summary" do
      before do
        team_summary # Create the team summary

        # Create criteria
        criteria_ids.each do |id|
          create(:judging_criterion, id: id)
        end
      end

      it "creates a team evaluation with the AI result" do
        expect {
          EvaluateTeamJob.perform_now(team_name, criteria_ids)
        }.to change { TeamEvaluation.count }.by(1)

        evaluation = TeamEvaluation.find_by(team_name: team_name)
        expect(evaluation.status).to eq("success")
        expect(evaluation.scores["Innovation"]["score"]).to eq(4.2)
        expect(evaluation.scores["Technical"]["score"]).to eq(4.5)
        expect(evaluation.total_score).to eq(4.37)
        expect(evaluation.comments).to eq("Overall great job")
      end
    end

    context "without a team summary" do
      it "creates a failed evaluation" do
        expect {
          EvaluateTeamJob.perform_now(team_name, criteria_ids)
        }.to change { TeamEvaluation.count }.by(1)

        evaluation = TeamEvaluation.find_by(team_name: team_name)
        expect(evaluation.status).to eq("failed")
        expect(evaluation.comments).to include("No successful team summary found")
      end
    end

    context "without criteria" do
      before do
        team_summary # Create the team summary
      end

      it "creates a failed evaluation" do
        expect {
          EvaluateTeamJob.perform_now(team_name, [])
        }.to change { TeamEvaluation.count }.by(1)

        evaluation = TeamEvaluation.find_by(team_name: team_name)
        expect(evaluation.status).to eq("failed")
        expect(evaluation.comments).to include("No judging criteria found")
      end
    end

    context "when AI client raises an error" do
      before do
        team_summary # Create the team summary

        # Create criteria
        criteria_ids.each do |id|
          create(:judging_criterion, id: id)
        end

        allow(mock_client).to receive(:evaluate_team).and_raise(StandardError.new("API error"))
      end

      it "creates a failed evaluation" do
        expect {
          EvaluateTeamJob.perform_now(team_name, criteria_ids)
        }.to change { TeamEvaluation.count }.by(1)

        evaluation = TeamEvaluation.find_by(team_name: team_name)
        expect(evaluation.status).to eq("failed")
        expect(evaluation.comments).to include("Error:")
      end
    end
  end
end
