class JudgingCriterionSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :weight, :created_at, :updated_at, :hackathon_id

  belongs_to :hackathon
end
