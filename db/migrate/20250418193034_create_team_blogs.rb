class CreateTeamBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :team_blogs do |t|
      t.string :team_name
      t.text :content
      t.string :status

      t.timestamps
    end
  end
end
