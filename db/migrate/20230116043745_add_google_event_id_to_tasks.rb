class AddGoogleEventIdToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :google_event_id, :string
  end
end
