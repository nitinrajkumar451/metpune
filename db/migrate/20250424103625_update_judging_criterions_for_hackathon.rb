class UpdateJudgingCriterionsForHackathon < ActiveRecord::Migration[8.0]
  def up
    # Find the default hackathon
    default_hackathon = Hackathon.find_by(name: "Metathon 2025")

    if default_hackathon
      # Update all judging criterions to associate with this default hackathon
      execute "UPDATE judging_criterions SET hackathon_id = #{default_hackathon.id} WHERE hackathon_id IS NULL"

      # Now make hackathon_id non-nullable
      change_column_null :judging_criterions, :hackathon_id, false
    end
  end

  def down
    # Make hackathon_id nullable again
    change_column_null :judging_criterions, :hackathon_id, true
  end
end
