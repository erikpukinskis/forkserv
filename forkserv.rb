require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'delayed_job_data_mapper'
require 'json'

Dir[File.dirname(__FILE__) + "/models/*.rb"].each { |f| require f }

DataMapper.setup(:default,
  :adapter  => 'mongo',
  :database => 'forkserv',
)

$config = YAML::load(File.read('config.yml'))

class ForkServ < Sinatra::Base
  configure do
    environment = Sinatra::Application.environment.to_s
  end

  post '/repos' do
    repo = Repo.create!
    content_type :json
    {'status' => 'ok', 'repo_id' => repo.id}.to_json
  end

  post '/repos/:id/files/:filename' do
    repo = Repo.find(params[:id])
    repo.save_file(params[:filename], params[:content])
    content_type :json
    {'status' => 'ok'}.to_json
  end

  get '/repos/:id/files/:filename' do
    repo = Repo.find(params[:id])
    repo.file_contents(params[:filename])
  end

  post '/repos/:id/deploy' do
    Delayed::Job.enqueue RepoJob.new(params[:id], :deploy)
    content_type :json
    {'status' => 'ok'}.to_json
  end

  post '/repos/:id/fork' do
    repo = Repo.find(params[:id])
    fork = repo.fork
    content_type :json
    {'status' => 'ok', 'repo_id' => fork.id}.to_json
  end

  get '/repos/:id' do
    repo = Repo.find(params[:id])
    content_type :json    
    {:id => repo.id, :uri => repo.uri}.to_json
  end

  get '/repos/:id/commits' do
    repo = Repo.find(params[:id])
    content_type :json
    repo.commits.to_json
  end

  post '/repos/:id/commits' do
    repo = Repo.find(params[:id])
    repo.commit(params[:message])
    content_type :json
    {'status' => 'ok'}.to_json
  end

  get '/repos/:id/trees/:sha/raw/:filename' do
    repo = Repo.find(params[:id])
    repo.raw(params[:sha], params[:filename])
  end
end
