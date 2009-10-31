$:.unshift *Dir[File.dirname(__FILE__) + "/vendor/*/lib"]

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'models/repo'
require 'activerecord'
require 'delayed_job'
require 'activerecord'
require 'models/repo_job'


$config = YAML::load(File.read('config.yml'))

set :port, ARGV[1] if ARGV[0] == "-p"



class ForkServ < Sinatra::Base

  configure do
    config = YAML::load(File.open('config/database.yml'))
    environment = Sinatra::Application.environment.to_s
    ActiveRecord::Base.logger = Logger.new($stdout)
    ActiveRecord::Base.establish_connection(
      config[environment]
    )
  end

  post '/repos' do
    repo = Repo.create!
    content_type :json
    {'status' => 'ok', 'repo_id' => repo.id}.to_json
  end

  post '/repos/:id/files/:filename' do
    repo = Repo.new(params[:id])
    repo.save_file(params[:filename], params[:content])
    content_type :json
    {'status' => 'ok'}.to_json
  end

  get '/repos/:id/files/:filename' do
    repo = Repo.new(params[:id])
    repo.file_contents(params[:filename])
  end

  post '/repos/:id/deploy' do
    Delayed::Job.enqueue RepoJob.new(params[:id], :deploy)
    content_type :json
    {'status' => 'ok'}.to_json
  end

  post '/repos/:id/fork' do
    repo = Repo.new(params[:id])
    fork = repo.fork
    content_type :json
    {'status' => 'ok', 'repo_id' => fork.id}.to_json
  end

  get '/repos/:id/commits' do
    repo = Repo.new(params[:id])
    repo.commits.to_json
  end

  post '/repos/:id/commits' do
    repo = Repo.new(params[:id])
    repo.commit(params[:message])
    {'status' => 'ok'}.to_json
  end

  get '/repos/:id/trees/:sha/raw/:filename' do
    repo = Repo.new(params[:id])
    repo.raw(params[:sha], params[:filename])
  end

end
