class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.belongs_to :entry
      t.string :name
      t.string :value
      t.string :ptype

      t.timestamps
    end
  end
end
