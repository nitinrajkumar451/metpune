class CreateJudgingCriterions < ActiveRecord::Migration[8.0]
  def change
    create_table :judging_criterions do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :weight, precision: 5, scale: 2, default: 1.0, null: false

      t.timestamps

      t.index :name, unique: true
    end
  end
end
