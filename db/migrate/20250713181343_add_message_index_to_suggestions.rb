class AddMessageIndexToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :message_index, :integer
  end
end
