require 'rails_helper'

RSpec.describe TeamBlog, type: :model do
  # Validations
  it { should validate_presence_of(:team_name) }
  it { should validate_inclusion_of(:status).in_array(%w[pending processing success failed]) }

  # Uniqueness validation test
  describe 'uniqueness validations' do
    before { create(:team_blog, team_name: "UniqueTeam") }

    it "validates uniqueness of team_name" do
      duplicate = build(:team_blog, team_name: "UniqueTeam")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:team_name]).to include("has already been taken")
    end
  end

  # Factory
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:team_blog)).to be_valid
    end

    it 'has valid trait factories' do
      expect(build(:team_blog, :pending)).to be_valid
      expect(build(:team_blog, :processing)).to be_valid
      expect(build(:team_blog, :failed)).to be_valid
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:pending_blog) { create(:team_blog, :pending, team_name: "PendingBlogTeam") }
    let!(:processing_blog) { create(:team_blog, :processing, team_name: "ProcessingBlogTeam") }
    let!(:success_blog) { create(:team_blog, team_name: "SuccessBlogTeam") }
    let!(:failed_blog) { create(:team_blog, :failed, team_name: "FailedBlogTeam") }

    it 'pending returns only pending blogs' do
      expect(TeamBlog.pending).to contain_exactly(pending_blog)
    end

    it 'processing returns only processing blogs' do
      expect(TeamBlog.processing).to contain_exactly(processing_blog)
    end

    it 'success returns only success blogs' do
      expect(TeamBlog.success).to contain_exactly(success_blog)
    end

    it 'failed returns only failed blogs' do
      expect(TeamBlog.failed).to contain_exactly(failed_blog)
    end
  end
end
