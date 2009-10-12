require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'
require 'models/repo'
require 'json'
require 'grit'
 
Spec::Matchers.define :be_a_directory do
  match do |actual|
    File.directory?(actual)
  end
end

Spec::Matchers.define :be_a_file do
  match do |actual|
    File.exists?(actual)
  end
end
 
describe 'Repo' do
  require 'forkserv'
 
  describe "after posting to /repos" do
    def response_object
      JSON.parse(response.body)
    rescue
      nil
    end

    def working_dir
      "#{Repo.working_dirs_root}/1444"
    end

    def response_should_be_ok
      @response.should be_ok
      response_object['status'].should == 'ok'
    end

    def file_contents(name)
      File.open(name, 'r') {|f| f.read}
    end

    before :all do
      FileUtils::rm_r(working_dir)
      Repo.stub!(:fresh_id).and_return("1444")
      post_it '/repos'
    end

    it "should return an OK response" do
      response_should_be_ok
    end

    it "should return the id" do
      response_object['repo_id'].should == '1444'
    end

    it "should create a working dir" do
      working_dir.should be_a_directory
    end

    it "should initialize a git repository" do
      lambda {Grit::Repo.new(working_dir)}.should_not raise_error
    end

    describe "posting some file contents" do
      before :all do
        post_it '/repos/1444/files/app.rb', {:content => "blah"}
      end

      it "should give a response" do
        response_should_be_ok
      end

      it "should create the file" do
        "#{working_dir}/app.rb".should be_a_file
      end

      it "should write the text" do
        file_contents("#{working_dir}/app.rb").should == "blah"
      end

      it "should have added the file to the tree" do
        # repo.tree.contents[0].name.should == "ar"
      end
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

