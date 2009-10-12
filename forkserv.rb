require 'rubygems'
require 'sinatra'

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
