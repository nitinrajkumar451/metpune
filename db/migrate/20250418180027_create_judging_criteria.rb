class CreateJudgingCriteria < ActiveRecord::Migration[8.0]
  def change
    create_table :judging_criteria do |t|
      t.string :name
      t.text :description
      t.decimal :weight

      t.timestamps
    end
  end
end
