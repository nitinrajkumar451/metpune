class AddHackathonToTeamEvaluations < ActiveRecord::Migration[8.0]
  def change
    # Initially add with null: true to allow migration of existing data
    add_reference :team_evaluations, :hackathon, null: true, foreign_key: true
    
    # Add index on hackathon_id and team_name for better query performance
    add_index :team_evaluations, [:hackathon_id, :team_name], unique: true
  end
end
