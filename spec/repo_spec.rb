require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'
require 'models/repo'
require 'json'
 
Spec::Matchers.define :be_a_directory do
  match do |actual|
    File.directory?(actual)
  end
end
 
describe 'Repo' do
  require 'forkserv'
 
  describe "after posting to /repos" do
    before :all do
      Repo.stub!(:fresh_id).and_return("1444")
      post_it '/repos'
    end

    def response_object
      JSON.parse(response.body)
    rescue
      nil
    end

    it "should return an OK response" do
      @response.should be_ok
      response_object['status'].should == 'ok'
    end

    it "should return the id" do
      response_object['repo_id'].should == '1444'
    end

    it "should create a working dir" do
      working_dir = "#{Repo.working_dirs_root}/1444"
      working_dir.should be_a_directory
    end

    it "should initialize a git repository" do

    end
  end
end

__END__

  specify "should render hello at /" do
    get_it '/'
    @response.should be_ok
    @response.body.should == "Hello"
  end
 
  specify "should render argument at /anything" do
    get_it '/foo'
    @response.should be_ok
    @response.body.should == "Hello foo"
 
    get_it '/bar'
    @response.should be_ok
    @response.body.should == "Hello bar"
  end
 
  specify "should not respond to nested paths" do
    get_it '/foo/bar'
    @response.should_not be_ok
  end

