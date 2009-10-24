require 'rubygems'
require 'sinatra'
require 'models/repo'

set :port, ARGV[1] if ARGV[0] == "-p"
$config = YAML::load(File.read('config.yml'))

post '/repos' do
  repo = Repo.new
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
  repo = Repo.new(params[:id])
  repo.deploy
  content_type :json
  {'status' => 'ok', 'uri' => repo.uri}.to_json
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
