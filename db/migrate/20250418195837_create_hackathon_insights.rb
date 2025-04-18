class CreateHackathonInsights < ActiveRecord::Migration[8.0]
  def change
    create_table :hackathon_insights do |t|
      t.text :content
      t.string :status

      t.timestamps
    end
  end
end
