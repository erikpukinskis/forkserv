require 'forkserv'
require File.dirname(__FILE__) + "/vendor/delayed_job/tasks/tasks"

namespace :db do
  task :migrate do
    ActiveRecord::Migrator.migrate(
      'db/migrate',
      ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    )
  end
end

task :spec do
  require 'spec/rake/spectask'
 
  Spec::Rake::SpecTask.new do |t|
    t.spec_opts = %w{--colour --format progress --loadby mtime --reverse}
    t.spec_files = FileList['spec/*_spec.rb']
  end
end
 
