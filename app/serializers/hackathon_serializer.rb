class HackathonSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :start_date, :end_date, :status, :created_at, :updated_at
  
  attribute :team_count do
    object.team_summaries.select(:team_name).distinct.count
  end
  
  attribute :submission_count do
    object.submissions.count
  end
end