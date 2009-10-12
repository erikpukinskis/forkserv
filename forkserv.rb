require 'rubygems'
require 'sinatra'

post '/repos' do
  repo = Repo.new
  content_type :json
  {'status' => 'ok', 'repo_id' => repo.id}.to_json
end
