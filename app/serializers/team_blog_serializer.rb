class TeamBlogSerializer < ActiveModel::Serializer
  attributes :id, :team_name, :content, :status, :created_at, :updated_at
end
