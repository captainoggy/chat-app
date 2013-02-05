class AddIpAddressToUsers < ActiveRecord::Migration
  def up
    execute 'alter table users add column ip_address inet'
  end
  def down
    execute 'alter table users drop column ip_address'
  end
end
