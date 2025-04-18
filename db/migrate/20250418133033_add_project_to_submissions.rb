class AddProjectToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :project, :string
  end
end
