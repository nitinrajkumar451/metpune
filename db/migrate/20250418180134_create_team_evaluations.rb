class CreateTeamEvaluations < ActiveRecord::Migration[8.0]
  def change
    create_table :team_evaluations do |t|
      t.string :team_name, null: false
      t.jsonb :scores, default: {}, null: false
      t.decimal :total_score, precision: 5, scale: 2
      t.text :comments
      t.string :status, default: "pending", null: false

      t.timestamps

      t.index :team_name, unique: true
    end
  end
end
