class CreateRepos < ActiveRecord::Migration
	def self.up
		create_table :repos do |t|
			t.string   :uri
			t.timestamps
		end
	end
end

