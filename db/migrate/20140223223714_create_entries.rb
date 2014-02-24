class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.belongs_to :collection
      t.string :name

      t.timestamps
    end
  end
end
