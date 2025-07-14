class CreateSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :suggestions do |t|
      t.text :content
      t.string :suggestion_type
      t.decimal :confidence
      t.string :priority
      t.text :audio_data

      t.timestamps
    end
  end
end
