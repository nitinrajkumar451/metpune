require 'rails_helper'

RSpec.describe HackathonInsight, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      insight = HackathonInsight.new(status: "pending")
      expect(insight).to be_valid
    end

    it "is invalid with an invalid status" do
      insight = HackathonInsight.new(status: "invalid")
      expect(insight).to be_invalid
    end

    it "is valid with each allowed status" do
      %w[pending processing success failed].each do |status|
        insight = HackathonInsight.new(status: status)
        expect(insight).to be_valid
      end
    end
  end

  describe "scopes" do
    before do
      HackathonInsight.create!(status: "pending")
      HackathonInsight.create!(status: "processing")
      HackathonInsight.create!(status: "success")
      HackathonInsight.create!(status: "failed")
    end

    it "returns pending insights" do
      expect(HackathonInsight.pending.count).to eq(1)
    end

    it "returns processing insights" do
      expect(HackathonInsight.processing.count).to eq(1)
    end

    it "returns successful insights" do
      expect(HackathonInsight.success.count).to eq(1)
    end

    it "returns failed insights" do
      expect(HackathonInsight.failed.count).to eq(1)
    end

    it "returns the latest insights first" do
      # Create a new insight with a later timestamp
      latest = HackathonInsight.create!(status: "success")
      expect(HackathonInsight.latest.first).to eq(latest)
    end
  end
end
