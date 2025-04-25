class RemoveUniqueIndexFromTeamEvaluations < ActiveRecord::Migration[8.0]
  def up
    # Remove the redundant team_name unique index
    remove_index :team_evaluations, :team_name, unique: true
  end

  def down
    # Re-add the index if needed to rollback
    add_index :team_evaluations, :team_name, unique: true
  end
end
