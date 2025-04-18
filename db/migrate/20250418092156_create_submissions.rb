class CreateSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :submissions do |t|
      t.string :team_name, null: false
      t.string :filename, null: false
      t.string :file_type, null: false
      t.string :source_url, null: false
      t.text :raw_text
      t.string :status, default: 'pending', null: false

      t.timestamps
    end
    
    add_index :submissions, :team_name
    add_index :submissions, :file_type
    add_index :submissions, :status
  end
end
