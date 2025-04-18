require 'rails_helper'

RSpec.describe JudgingCriterion, type: :model do
  # Validations
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:weight) }
  it { should validate_numericality_of(:weight).is_greater_than(0) }

  # Uniqueness validation test
  describe 'uniqueness validations' do
    before { create(:judging_criterion, name: "Unique Criterion") }

    it "validates uniqueness of name" do
      duplicate = build(:judging_criterion, name: "Unique Criterion")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  # Factory
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:judging_criterion)).to be_valid
    end

    it 'has valid trait factories' do
      expect(build(:judging_criterion, :innovation)).to be_valid
      expect(build(:judging_criterion, :technical_execution)).to be_valid
      expect(build(:judging_criterion, :impact)).to be_valid
      expect(build(:judging_criterion, :presentation)).to be_valid
      expect(build(:judging_criterion, :completeness)).to be_valid
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:criterion1) { create(:judging_criterion, name: "B Criterion") }
    let!(:criterion2) { create(:judging_criterion, name: "A Criterion") }
    let!(:criterion3) { create(:judging_criterion, name: "C Criterion") }

    it 'ordered returns criteria in alphabetical order by name' do
      ordered_criteria = JudgingCriterion.ordered
      expect(ordered_criteria.map(&:name)).to eq([ "A Criterion", "B Criterion", "C Criterion" ])
    end
  end

  # Instance methods
  describe '#to_s' do
    let(:criterion) { build(:judging_criterion, name: "Test Criterion") }

    it 'returns the name of the criterion' do
      expect(criterion.to_s).to eq("Test Criterion")
    end
  end
end
