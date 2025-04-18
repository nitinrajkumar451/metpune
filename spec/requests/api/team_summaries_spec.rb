require 'rails_helper'

RSpec.describe "Api::TeamSummaries", type: :request do
  describe "GET /api/team_summaries" do
    before do
      # Regular team summaries already have status: "success" from the factory definition
      create_list(:team_summary, 2)
      create(:team_summary, :pending)
      create(:team_summary, :failed)
    end

    it "returns a list of all team summaries" do
      get "/api/team_summaries"

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      team_summaries = json_response["team_summaries"]
      expect(team_summaries.size).to eq(4)
    end

    context "when filtering by status" do
      it "returns only team summaries with the specified status" do
        get "/api/team_summaries", params: { status: "success" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        team_summaries = json_response["team_summaries"]
        expect(team_summaries.size).to eq(2)
        expect(team_summaries.map { |s| s["status"] }).to all(eq("success"))
      end
    end
  end

  describe "GET /api/team_summaries/:team_name" do
    let(:team_summary) { create(:team_summary) }

    it "returns the specified team summary" do
      get "/api/team_summaries/#{team_summary.team_name}"

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["team_summary"]["team_name"]).to eq(team_summary.team_name)
      expect(json_response["team_summary"]["content"]).to include("Team Report")
    end

    context "when the team summary does not exist" do
      it "returns a not found response" do
        get "/api/team_summaries/nonexistent"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/team_summaries/generate" do
    let(:team_name) { "TestTeam" }

    before do
      # Create some successful submissions for the team
      create_list(:submission, 3, :success, team_name: team_name)

      # Allow the job to be enqueued without actually performing it
      allow(GenerateTeamSummaryJob).to receive(:perform_later)
    end

    it "enqueues a job to generate the team summary" do
      expect {
        post "/api/team_summaries/generate", params: { team_name: team_name }
      }.to change { TeamSummary.count }.by(1)

      expect(GenerateTeamSummaryJob).to have_received(:perform_later).with(team_name)
      expect(response).to have_http_status(:ok)
    end

    it "creates a pending team summary" do
      post "/api/team_summaries/generate", params: { team_name: team_name }

      team_summary = TeamSummary.find_by(team_name: team_name)
      expect(team_summary.status).to eq("pending")
    end

    context "when no team name is provided" do
      it "returns a bad request response" do
        post "/api/team_summaries/generate"

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to include("required")
      end
    end

    context "when the team has no successful submissions" do
      it "returns a bad request response" do
        post "/api/team_summaries/generate", params: { team_name: "NonexistentTeam" }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to include("No successful submissions")
      end
    end
  end
end
