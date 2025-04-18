require 'rails_helper'

RSpec.describe GenerateHackathonInsightsJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    context "when successful team summaries exist" do
      before do
        TeamSummary.create!(
          team_name: "Test Team",
          content: "This is a test team summary",
          status: "success"
        )
      end

      it "creates a new hackathon insight" do
        expect {
          GenerateHackathonInsightsJob.new.perform
        }.to change(HackathonInsight, :count).by(1)
      end

      it "sets the status to success" do
        GenerateHackathonInsightsJob.new.perform
        expect(HackathonInsight.last.status).to eq("success")
      end

      it "calls the AI client to generate insights" do
        client_mock = instance_double(Ai::Client)
        allow(Ai::Client).to receive(:new).and_return(client_mock)
        allow(client_mock).to receive(:generate_hackathon_insights).and_return("Test insights content")

        GenerateHackathonInsightsJob.new.perform

        expect(client_mock).to have_received(:generate_hackathon_insights)
        expect(HackathonInsight.last.content).to eq("Test insights content")
      end
    end

    context "when no successful team summaries exist" do
      it "creates a new hackathon insight with failed status" do
        expect {
          GenerateHackathonInsightsJob.new.perform
        }.to change(HackathonInsight, :count).by(1)

        expect(HackathonInsight.last.status).to eq("failed")
        expect(HackathonInsight.last.content).to include("No successful team summaries found")
      end
    end

    context "when an error occurs" do
      before do
        TeamSummary.create!(
          team_name: "Test Team",
          content: "This is a test team summary",
          status: "success"
        )

        allow_any_instance_of(Ai::Client).to receive(:generate_hackathon_insights).and_raise("Test error")
      end

      it "handles the error and sets the status to failed" do
        expect {
          GenerateHackathonInsightsJob.new.perform
        }.to change(HackathonInsight, :count).by(1)

        expect(HackathonInsight.last.status).to eq("failed")
        expect(HackathonInsight.last.content).to include("Error:")
      end
    end
  end
end
