class DropJudgingCriteria < ActiveRecord::Migration[8.0]
  def up
    drop_table :judging_criteria
  end

  def down
    create_table :judging_criteria do |t|
      t.string :name
      t.text :description
      t.decimal :weight

      t.timestamps
    end
  end
end
