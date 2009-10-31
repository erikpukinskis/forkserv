class CreateRepos < ActiveRecord::Migration
	def self.up
		create_table :repos do |t|
			t.string   :heroku_name
			t.timestamps
		end
	end
end

