class CreateHackathons < ActiveRecord::Migration[8.0]
  def change
    create_table :hackathons do |t|
      t.string :name, null: false
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :status, null: false, default: "active"

      t.timestamps
    end
    
    add_index :hackathons, :name, unique: true
  end
end
