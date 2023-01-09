class AddFieldsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :venue, :string
    add_column :events, :description, :text
  end
end
