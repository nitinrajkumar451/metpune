class CreateDefaultHackathonAndUpdateRecords < ActiveRecord::Migration[8.0]
  def up
    # Create a default hackathon
    default_hackathon = Hackathon.create!(
      name: "Metathon 2025",
      description: "The inaugural Metathon hackathon focused on AI and document processing.",
      start_date: Date.new(2025, 4, 1),
      end_date: Date.new(2025, 4, 20),
      status: "active"
    )
    
    # Update all existing records to associate with this default hackathon
    # Submissions
    execute "UPDATE submissions SET hackathon_id = #{default_hackathon.id} WHERE hackathon_id IS NULL"
    
    # Team Summaries
    execute "UPDATE team_summaries SET hackathon_id = #{default_hackathon.id} WHERE hackathon_id IS NULL"
    
    # Team Evaluations
    execute "UPDATE team_evaluations SET hackathon_id = #{default_hackathon.id} WHERE hackathon_id IS NULL"
    
    # Team Blogs
    execute "UPDATE team_blogs SET hackathon_id = #{default_hackathon.id} WHERE hackathon_id IS NULL"
    
    # Hackathon Insights
    execute "UPDATE hackathon_insights SET hackathon_id = #{default_hackathon.id} WHERE hackathon_id IS NULL"
    
    # We'll update judging criterions later in a separate migration after adding the column
    
    # Now make hackathon_id non-nullable in all tables
    change_column_null :submissions, :hackathon_id, false
    change_column_null :team_summaries, :hackathon_id, false
    change_column_null :team_evaluations, :hackathon_id, false
    change_column_null :team_blogs, :hackathon_id, false
    change_column_null :hackathon_insights, :hackathon_id, false
    # We'll set this to non-nullable later in a separate migration
  end
  
  def down
    # No way to determine which records were previously associated with the default hackathon
    # Don't attempt to revert the associations
    
    # Make hackathon_id nullable again
    change_column_null :submissions, :hackathon_id, true
    change_column_null :team_summaries, :hackathon_id, true
    change_column_null :team_evaluations, :hackathon_id, true
    change_column_null :team_blogs, :hackathon_id, true
    change_column_null :hackathon_insights, :hackathon_id, true
    # No change needed for judging_criterions at this stage
    
    # Delete the default hackathon
    Hackathon.where(name: "Metathon 2025").delete_all
  end
end