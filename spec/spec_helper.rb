dir = "/tmp/forkserv_working_dirs/test"
FileUtils::rm_r(dir) if File.directory?(dir)

Spec::Runner.configure do |config|
  config.before(:each) do
    file = File.expand_path(File.dirname(__FILE__) + '/../db/test.sqlite3')
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => file)
  end
end