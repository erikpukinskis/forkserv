require 'grit'

class String
  def starts_with(beginning)
    self[0,beginning.length] == beginning
  end
end

class Repo
  attr_accessor :id

  def initialize(id = nil)
    if id
      self.id = id
    else
      self.id = Repo.fresh_id
      make_dir
      initialize_git
    end
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

  def save_file(name, content)
    path = File.expand_path("#{working_dir}/#{name}")
    raise "Tried to write a file out of bounds" unless path.starts_with working_dir
    File.open(path, 'w') {|f| f.write(content) }
  end

  def Repo.working_dirs_root 
    '/tmp/forkserv_working_dirs' 
  end
end
