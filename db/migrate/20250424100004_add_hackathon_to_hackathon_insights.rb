class AddHackathonToHackathonInsights < ActiveRecord::Migration[8.0]
  def change
    # Initially add with null: true to allow migration of existing data
    add_reference :hackathon_insights, :hackathon, null: true, foreign_key: true
  end
end
