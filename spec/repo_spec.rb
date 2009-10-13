require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'
require 'models/repo'
require 'json'
require 'grit'
require 'net/http'
 
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
    before :all do
      @repo_id = "1444"
      Repo.stub!(:fresh_id).and_return(@repo_id)
      FileUtils::rm_r(working_dir) if File.directory?(working_dir)
      post '/repos'
    end

    def response_object
      JSON.parse(response.body)
    rescue
      nil
    end

    def working_dir
      "#{Repo.working_dirs_root}/#{@repo_id}"
    end

    def response_should_be_ok
      @response.should be_ok
      response_object['status'].should == 'ok'
    end

    def file_contents(name)
      File.open(name, 'r') {|f| f.read}
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
        @repo_id = "1234"
        Repo.stub!(:fresh_id).and_return(@repo_id)
        FileUtils::rm_r(working_dir) if File.directory?(working_dir)
        post '/repos'
        post '/repos/1234/files/app.rb', {:content => "blah"}
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
        repo = Grit::Repo.new(working_dir)
        repo.tree.contents.length.should == 1
        repo.tree.contents[0].name.should == "app.rb"
      end
    end

    describe "getting file contents" do
      before :all do
        @repo_id = "1111"
        Repo.stub!(:fresh_id).and_return(@repo_id)
        FileUtils::rm_r(working_dir) if File.directory?(working_dir)
        post '/repos'
        post '/repos/1111/files/app.rb', {:content => "blah"}
      end

      it "should return the contents" do
        get '/repos/1111/files/app.rb'
        @response.body.should == "blah"
      end
    end

    #
    # NOTE: This scenario is disabled because I don't want
    #       to hit Heroku all the time.  Uncomment the post
    #       in the before and remove all the pendings to
    #       actually run it
    #
    describe "posting a complete sinatra app" do
      before :all do
        @repo_id = "1222"
        Repo.stub!(:fresh_id).and_return(@repo_id)
        FileUtils::rm_r(working_dir) if File.directory?(working_dir)
        post '/repos'
        post '/repos/1222/files/app.rb', {:content => "
          require 'rubygems'
          require 'sinatra'
    
          get '/' do
            'hello world!'
          end
        "}
        post '/repos/1222/files/config.ru', {:content => "
          require 'app'
          run Sinatra::Application
        "}
        #post '/repos/1222/deploy'
      end

      it "should give a response" do
        pending
        response_should_be_ok
      end

      it "should return a heroku url" do
        pending
        response_object['uri'].should match(/http:\/\/[a-z0-9-]{5,}\.heroku\.com/)
      end

      it "should be running and say hello world" do
        pending
        http_response = Net::HTTP.get_response(URI.parse(response_object['uri']))  
        http_response.body.should match(/hello world!/)
      end
    end
  end
end
