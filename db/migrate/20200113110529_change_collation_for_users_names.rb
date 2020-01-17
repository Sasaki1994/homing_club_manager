class ChangeCollationForUsersNames < ActiveRecord::Migration[5.2]
  def up
    execute("ALTER TABLE users MODIFY line_id varchar(255) BINARY")
  end
end
