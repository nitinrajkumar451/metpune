class Submission < ApplicationRecord
  # Validations
  validates :team_name, :filename, :file_type, :source_url, :status, presence: true
  validates :file_type, inclusion: { in: %w[pdf pptx docx jpg png zip] }
  validates :status, inclusion: { in: %w[pending processing success failed] }
  
  # Project is optional to maintain compatibility with existing records
  validates :project, length: { maximum: 255 }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :success, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :by_project, ->(project) { where(project: project) if project.present? }

  # File type methods
  def document?
    %w[pdf docx].include?(file_type)
  end

  def presentation?
    file_type == "pptx"
  end

  def image?
    %w[jpg png].include?(file_type)
  end

  def archive?
    file_type == "zip"
  end
end
