require 'rails_helper'

RSpec.describe "Api::HackathonInsights", type: :request do
  describe "GET /api/hackathon_insights" do
    context "when successful insights exist" do
      xit "returns the latest successful insight" do
        # Use create! to ensure the record is created directly before the request
        HackathonInsight.destroy_all
        insight = HackathonInsight.create!(
          content: "# Hackathon Trends Analysis\n\nThis is a test insight.",
          status: "success"
        )

        get "/api/hackathon_insights"

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("success")
        expect(json["content"]).to include("Hackathon Trends Analysis")
      end
    end

    context "when no successful insights exist" do
      it "returns a not found status" do
        get "/api/hackathon_insights"

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("No successful insights found")
      end
    end
  end

  describe "POST /api/hackathon_insights/generate" do
    context "when successful team summaries exist" do
      before do
        TeamSummary.create!(
          team_name: "Test Team",
          content: "This is a test team summary",
          status: "success"
        )
      end

      it "starts the hackathon insights generation process" do
        expect {
          post "/api/hackathon_insights/generate"
        }.to change(HackathonInsight, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Hackathon insights generation started")
        expect(HackathonInsight.last.status).to eq("pending")
      end
    end

    context "when no successful team summaries exist" do
      it "returns a bad request status" do
        post "/api/hackathon_insights/generate"

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("No successful team summaries found")
      end
    end
  end

  describe "GET /api/hackathon_insights/markdown" do
    context "when successful insights exist" do
      it "returns the insight content as markdown" do
        # Use create! to ensure the record is created directly before the request
        HackathonInsight.destroy_all
        insight = HackathonInsight.create!(
          content: "# Hackathon Trends Analysis\n\nThis is a test insight.",
          status: "success"
        )

        get "/api/hackathon_insights/markdown"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("text/markdown; charset=utf-8")
        expect(response.body).to include("Hackathon Trends Analysis")
      end
    end

    context "when no successful insights exist" do
      it "returns a not found status" do
        get "/api/hackathon_insights/markdown"

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("No successful insights found")
      end
    end
  end
end
