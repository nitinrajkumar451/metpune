class JudgingCriterionSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :weight, :created_at, :updated_at
end
