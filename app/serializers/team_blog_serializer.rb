class TeamBlogSerializer < ActiveModel::Serializer
  attributes :id, :team_name, :content, :status, :created_at, :updated_at, :hackathon_id

  belongs_to :hackathon
end
