class RepoJob
  def initialize(id, action)
    @id = id
    @action = action
  end

  def repo
    @repo ||= Repo.new(@id)
  end

  def perform
    repo.send(action)
  end
end
