class TeamEvaluationSerializer < ActiveModel::Serializer
  attributes :id, :team_name, :scores, :total_score, :comments, :status, :created_at, :updated_at
end
