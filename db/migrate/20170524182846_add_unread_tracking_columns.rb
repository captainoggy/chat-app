class AddUnreadTrackingColumns < ActiveRecord::Migration
  def up
    # no op, no need to create all data, next migration will delete it
  end

  def down
    raise "Can not be reverted"
  end
end
