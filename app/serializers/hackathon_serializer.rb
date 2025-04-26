class HackathonSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :start_date, :end_date, :status, :created_at, :updated_at
  
  attribute :team_count do
    # First try to get count from team_summaries
    team_summary_count = object.team_summaries.select(:team_name).distinct.count
    
    # If no team summaries exist, count unique team names from submissions instead
    if team_summary_count == 0
      object.submissions.select(:team_name).distinct.count
    else
      team_summary_count
    end
  end
  
  attribute :submission_count do
    object.submissions.count
  end
end