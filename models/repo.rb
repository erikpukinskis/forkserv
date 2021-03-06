require 'grit'
require 'heroku'
require 'mongo_adapter'

module Grit
  class Repo
    def cmd(command)
      FileUtils.chdir working_dir      
      `git #{command}`
    end

    def self.init(dir)
      FileUtils.chdir dir
      `git init`
    end

    def remotes
      cmd("remote").split(/\n/)
    end

    def add_remote(name, uri)
      cmd "remote add #{name} #{uri}"
    end

    def push(remote, branch)
      cmd "push #{remote} #{branch}"
    end

    def clone(dir)
      cmd "clone #{working_dir} #{dir}"
    end
  end
end

class String
  def starts_with(beginning)
    self[0,beginning.length] == beginning
  end
end

class Repo
  include DataMapper::Mongo::Resource
  property :id, ObjectId
  property :heroku_name, String
  property :active, Boolean, :default => true

  after :create do
    make_dir
    initialize_git
  end

  def git
    @git ||= Grit::Repo.new(working_dir)
  end

  def make_dir
    FileUtils.mkdir_p(working_dir)
  end

  def initialize_git
    Grit::Repo.init(working_dir)
  end

  def working_dir
    "#{Repo.working_dirs_root}/#{id}"
  end

  def clean(name)
    path = File.expand_path("#{working_dir}/#{name}")
    raise "Tried to write a file out of bounds" unless path.starts_with working_dir
    path[working_dir.length+1..path.length]
  end

  def save_file(name, content)
    path = clean(name)
    FileUtils::chdir(working_dir)
    File.open(path, 'w') {|f| f.write(content) }
    git.add(name)
  end

  def commit(message)
    message ||= "something"
    git.commit_index(message)
  end

  def file_contents(name)
    path = "#{working_dir}/#{clean(name)}"
    File.open(path, 'r') {|f| f.read }
  end

  def Repo.working_dirs_root 
    "/tmp/forkserv_working_dirs/#{Sinatra::Application.environment.to_s}"
  end


  def heroku
    @heroku ||= Heroku::Client.new($config['heroku_username'], $config['heroku_password'])
  end

  def created?
    git.remotes.include?('heroku')
  end

  def heroku_create
    update_attributes(:heroku_name => heroku.create)
    git.add_remote('heroku', "git@heroku.com:#{heroku_name}.git")
  end

  def deploy
    heroku_create unless created? 
    f = git.push('heroku', 'master')
  end

  def fork
    repo = Repo.new(Repo.fresh_id)
    git.clone(repo.working_dir)
    repo
  end

  def uri
    if heroku_name
      "http://#{heroku_name}.heroku.com"
    else
      nil
    end
  end

  def commits
    git.commits.inject([]) do |all,commit| 
      all << {"sha" => commit.sha, "message" => commit.message, "date" => commit.date.to_i}
    end.reverse
  end

  def raw(sha, filename)
    git.tree(sha, filename).contents[0].data
  end
end
