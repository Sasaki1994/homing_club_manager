class CreateMenus < ActiveRecord::Migration[5.2]
  def change
    create_table :menus do |t|
      t.string :label
      t.string :menu_id
      t.timestamps
    end
  end
end
