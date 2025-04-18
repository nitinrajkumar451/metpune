class SubmissionSummarySerializer < ActiveModel::Serializer
  attributes :id, :team_name, :filename, :file_type, :project, :summary, :status, :created_at
end
