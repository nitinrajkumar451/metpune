class AddSummaryToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :summary, :text
  end
end
