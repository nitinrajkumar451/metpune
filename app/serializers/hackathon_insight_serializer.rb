class HackathonInsightSerializer < ActiveModel::Serializer
  attributes :id, :content, :status, :created_at, :updated_at
end
