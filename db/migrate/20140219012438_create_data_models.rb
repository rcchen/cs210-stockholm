class CreateDataModels < ActiveRecord::Migration
  def change
    create_table :data_models do |t|
      t.string :name
      t.string :attrs
      t.string :base_url
      t.timestamps
    end
  end
end
