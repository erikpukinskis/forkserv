require 'grit'
require 'heroku'

module Grit
  class Repo
    def remotes
      FileUtils.chdir working_dir
      `git remote`.split(/\n/)
    end

    def add_remote(name, uri)
      FileUtils.chdir working_dir
      `git remote add #{name} #{uri}`
    end

    def push(remote, branch)
      FileUtils.chdir working_dir
      `git push #{remote} #{branch}`
    end
  end
end

class String
  def starts_with(beginning)
    self[0,beginning.length] == beginning
  end
end

class Repo
  attr_accessor :id, :uri, :heroku_name

  def initialize(id = nil)
    if id
      self.id = id
    else
      self.id = Repo.fresh_id
      m = make_dir
      initialize_git
    end
  end

  def Repo.fresh_id
    while(candidate = rand(10**10))
      repo = Repo.new(candidate)
      break if !File.directory?(repo.working_dir)
    end
    candidate
  end

  def git
    @git ||= Grit::Repo.new(working_dir)
  end

  def make_dir
    FileUtils.mkdir_p(working_dir)
  end

  def initialize_git
    Grit::Repo.init_bare("#{working_dir}/.git")
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
    git.commit_index("saved #{name}")
  end

  def file_contents(name)
    File.open(clean(name), 'r') {|f| f.read }
  end

  def Repo.working_dirs_root 
    '/tmp/forkserv_working_dirs' 
  end


  def heroku
    @heroku ||= Heroku::Client.new($config['heroku_username'], $config['heroku_password'])
  end

  def created?
    git.remotes.include?('heroku')
  end

  def create
    self.heroku_name = heroku.create
    git.add_remote('heroku', "git@heroku.com:#{heroku_name}.git")
  end

  def deploy
    create unless created? 
    debugger
    f = git.push('heroku', 'master')
  end

  def uri
    nil unless heroku_name
    "http://#{heroku_name}.heroku.com"
  end
end
