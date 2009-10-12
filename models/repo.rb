class Repo
  attr_accessor :id

  def initialize
    self.id = Repo.fresh_id
  end
end
