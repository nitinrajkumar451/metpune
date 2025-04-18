class SubmissionSerializer < ActiveModel::Serializer
  attributes :id, :team_name, :filename, :file_type, :source_url, :status,
             :created_at, :updated_at, :project, :raw_text, :summary
end
