class AddHackathonToJudgingCriterions < ActiveRecord::Migration[8.0]
  def change
    # Initially add with null: true to allow migration of existing data
    add_reference :judging_criterions, :hackathon, null: true, foreign_key: true

    # Update uniqueness constraint to be scoped by hackathon
    remove_index :judging_criterions, :name if index_exists?(:judging_criterions, :name)
    add_index :judging_criterions, [ :hackathon_id, :name ], unique: true
  end
end
