ENV['RACK_ENV'] = "test"

dir = "/tmp/forkserv_working_dirs/test"
FileUtils::rm_r(dir) if File.directory?(dir)

require File.join(File.dirname(__FILE__), "..", "forkserv")
require 'rack/test'
 
Spec::Matchers.define :be_a_directory do
  match do |actual|
    File.directory?(actual)
  end
end

Spec::Matchers.define :be_a_file do
  match do |actual|
    File.exists?(actual)
  end
end
 
set :environment, :test

RSpec.configure do |config|
  config.before(:each) do

  end
end
