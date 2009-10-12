class Repo
  attr_accessor :id

  def initialize
    self.id = Repo.fresh_id
    make_dir
  end

  def make_dir
    FileUtils.mkdir_p(working_dir)
  end

  def working_dir
    "#{Repo.working_dirs_root}/#{id}"
  end

  def Repo.working_dirs_root 
    '/tmp/forkserv_working_dirs' 
  end
end
