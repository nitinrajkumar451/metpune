class AddHackathonToTeamSummaries < ActiveRecord::Migration[8.0]
  def change
    # Initially add with null: true to allow migration of existing data
    add_reference :team_summaries, :hackathon, null: true, foreign_key: true

    # Update the uniqueness constraint to be scoped by hackathon
    remove_index :team_summaries, :team_name if index_exists?(:team_summaries, :team_name)
    add_index :team_summaries, [ :hackathon_id, :team_name ], unique: true
  end
end
