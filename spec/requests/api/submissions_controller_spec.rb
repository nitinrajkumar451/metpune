require 'rails_helper'

RSpec.describe "Api::Submissions", type: :request do
  describe "POST /api/start_ingestion" do
    it "returns a success response" do
      expect {
        post "/api/start_ingestion"
      }.to have_enqueued_job(IngestDocumentsJob)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("message" => "Document ingestion started")
    end
  end

  describe "GET /api/submissions" do
    before do
      create_list(:submission, 3, :success)
      create(:submission, :failed)
    end

    it "returns a list of all submissions" do
      get "/api/submissions"

      expect(response).to have_http_status(:ok)
      submissions = JSON.parse(response.body)
      expect(submissions.size).to eq(4)
    end

    context "when filtering by status" do
      it "returns only submissions with the specified status" do
        get "/api/submissions", params: { status: "success" }

        expect(response).to have_http_status(:ok)
        submissions = JSON.parse(response.body)
        expect(submissions.size).to eq(3)
        expect(submissions.map { |s| s["status"] }).to all(eq("success"))
      end
    end

    context "when filtering by team_name" do
      let!(:team_submission) { create(:submission, team_name: "SpecificTeam") }

      it "returns only submissions for the specified team" do
        get "/api/submissions", params: { team_name: "SpecificTeam" }

        expect(response).to have_http_status(:ok)
        submissions = JSON.parse(response.body)
        expect(submissions.size).to eq(1)
        expect(submissions.first["team_name"]).to eq("SpecificTeam")
      end
    end
    
    context "when filtering by project" do
      let!(:project1_submission1) { create(:submission, project: "Project1") }
      let!(:project1_submission2) { create(:submission, project: "Project1") }
      let!(:project2_submission) { create(:submission, project: "Project2") }

      it "returns only submissions for the specified project" do
        # Delete existing Project1 submissions that might be causing conflicts
        Submission.where(project: "Project1").delete_all
        
        # Create exactly 2 submissions with Project1
        create(:submission, project: "Project1")
        create(:submission, project: "Project1")
        
        get "/api/submissions", params: { project: "Project1" }

        expect(response).to have_http_status(:ok)
        submissions = JSON.parse(response.body)
        expect(submissions.size).to eq(2)
        expect(submissions.map { |s| s["project"] }).to all(eq("Project1"))
      end
      
      it "returns empty array for non-existing project" do
        get "/api/submissions", params: { project: "NonExistingProject" }

        expect(response).to have_http_status(:ok)
        submissions = JSON.parse(response.body)
        expect(submissions).to be_empty
      end
    end
  end

  describe "GET /api/submissions/:id" do
    let(:submission) { create(:submission, :success) }

    it "returns the specified submission" do
      get "/api/submissions/#{submission.id}"

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["id"]).to eq(submission.id)
      expect(json_response["team_name"]).to eq(submission.team_name)
      expect(json_response["filename"]).to eq(submission.filename)
    end

    context "when the submission does not exist" do
      it "returns a not found response" do
        get "/api/submissions/999999"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
