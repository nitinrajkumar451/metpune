class HackathonInsightSerializer < ActiveModel::Serializer
  attributes :id, :content, :status, :created_at, :updated_at, :hackathon_id
  
  belongs_to :hackathon
end
