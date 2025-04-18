require 'rails_helper'

RSpec.describe Submission, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:team_name) }
    it { should validate_presence_of(:filename) }
    it { should validate_presence_of(:file_type) }
    it { should validate_presence_of(:source_url) }
    it { should validate_presence_of(:status) }
    
    it { should validate_inclusion_of(:file_type).in_array(['pdf', 'pptx', 'docx', 'jpg', 'png', 'zip']) }
    it { should validate_inclusion_of(:status).in_array(['pending', 'processing', 'success', 'failed']) }
  end
  
  describe 'defaults' do
    it 'sets status to pending by default' do
      submission = Submission.new
      expect(submission.status).to eq('pending')
    end
  end
  
  describe 'scopes' do
    before do
      create(:submission, status: 'pending')
      create(:submission, status: 'processing')
      create(:submission, status: 'success')
      create(:submission, status: 'failed')
    end

    it 'returns pending submissions' do
      expect(Submission.pending.count).to eq(1)
    end
    
    it 'returns processing submissions' do
      expect(Submission.processing.count).to eq(1)
    end
    
    it 'returns successful submissions' do
      expect(Submission.success.count).to eq(1)
    end
    
    it 'returns failed submissions' do
      expect(Submission.failed.count).to eq(1)
    end
  end
  
  describe 'file type methods' do
    it 'identifies document types correctly' do
      expect(build(:submission, file_type: 'pdf').document?).to be true
      expect(build(:submission, file_type: 'docx').document?).to be true
      expect(build(:submission, file_type: 'pptx').document?).to be false
    end
    
    it 'identifies presentation types correctly' do
      expect(build(:submission, file_type: 'pptx').presentation?).to be true
      expect(build(:submission, file_type: 'pdf').presentation?).to be false
    end
    
    it 'identifies image types correctly' do
      expect(build(:submission, file_type: 'jpg').image?).to be true
      expect(build(:submission, file_type: 'png').image?).to be true
      expect(build(:submission, file_type: 'pdf').image?).to be false
    end
    
    it 'identifies archive types correctly' do
      expect(build(:submission, file_type: 'zip').archive?).to be true
      expect(build(:submission, file_type: 'pdf').archive?).to be false
    end
  end
end