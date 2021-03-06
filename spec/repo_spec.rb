require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'ForkServ' do
  include Rack::Test::Methods

  def app
    ForkServ
  end
 
  def obj(resp)
    JSON.parse(resp.body)
  end

  def response_object
    JSON.parse(last_response.body)
  rescue
    nil
  end

  def working_dir(id)
    "#{Repo.working_dirs_root}/#{id}"
  end

  it "should give a proper environment" do
    Repo.working_dirs_root.should == "/tmp/forkserv_working_dirs/test"
  end

  describe "after posting to /repos" do
    before :all do
      post '/repos'
      @id = obj(last_response)['repo_id']
    end

    def file_contents(name)
      File.open(name, 'r') {|f| f.read}
    end

    it "should return an OK response" do
      last_response.should be_ok
    end

    it "should create a working dir" do
      working_dir(@id).should be_a_directory
    end

    it "should initialize a git repository" do
      lambda {Grit::Repo.new(working_dir(@id))}.should_not raise_error
    end

    describe "posting some file contents" do
      before :all do
        post '/repos'
        @id = obj(last_response)['repo_id']
        post "/repos/#{@id}/files/app.rb", {:content => "blah"}
        @original_response = last_response
        post "/repos/#{@id}/commits"
      end

      it "should give a response" do
        @original_response.should be_ok
      end

      it "should create the file" do
        "#{working_dir(@id)}/app.rb".should be_a_file
      end

      it "should write the text" do
        file_contents("#{working_dir(@id)}/app.rb").should == "blah"
      end

      it "should have added the file to the tree" do
        repo = Grit::Repo.new(working_dir(@id))
        repo.tree.contents.length.should == 1
        repo.tree.contents[0].name.should == "app.rb"
      end
    end

    describe "getting commits" do
      before :all do
        post '/repos'
        @id = obj(last_response)['repo_id']
        post "/repos/#{@id}/files/app.rb", {:content => "blah"}
        post "/repos/#{@id}/commits"
        get "/repos/#{@id}/commits"
      end

      it "should return one item" do
        last_response.should be_ok
        response_object.length.should == 1
      end
    end

    describe "getting an old file" do
      before :all do
        post '/repos'
        @id = obj(last_response)['repo_id']
        post "/repos/#{@id}/files/app.rb", {:content => "blah"}
        post "/repos/#{@id}/commits"
        get "/repos/#{@id}/commits"
        sha = response_object[0]["sha"]
        post "/repos/#{@id}/files/app.rb", {:content => "blee"}
        post "/repos/#{@id}/commits"
        get "/repos/#{@id}/trees/#{sha}/raw/app.rb"
      end

      it "should return the old contents" do
        last_response.body.should == "blah"
      end
    end

    describe "getting file contents" do
      before :all do
        post '/repos'
        @id = obj(last_response)['repo_id']
        post "/repos/#{@id}/files/app.rb", {:content => "blah"}
        post "/repos/#{@id}/commits"
        get "/repos/#{@id}/files/app.rb"
      end

      it "should return the contents" do
        last_response.body.should == "blah"
      end
    end

    describe "merging and committing in the style of autosave" do
      it "should not commit before we ask" do
        post "/repos"
        id = response_object['repo_id']
        post "/repos/#{id}/files/foo", {:content => "bar"}
        get "/repos/#{id}/commits"
        response_object.length.should == 0
      end

      it "should have a commit after we explicitly commit" do
        post "/repos"
        id = response_object['repo_id']
        post "/repos/#{id}/files/foo", {:content => "bar"}
        post "/repos/#{id}/commits", {:message => "the message"}
        get "/repos/#{id}/commits"
        response_object.length.should == 1
        response_object[0]['message'].should == "the message"
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
        post '/repos'
        id = response_object['repo_id']
        post "/repos/#{id}/files/app.rb", {:content => "
          require 'rubygems'
          require 'sinatra'
    
          get '/' do
            'hello world!'
          end
        "}
        post "/repos/#{id}/files/config.ru", {:content => "
          require 'app'
          run Sinatra::Application
        "}
        post "/repos/#{id}/commits"
        #post "/repos/#{id}/deploy"
        #Delayed::Job.work_off
        #get "/repos/#{id}"
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
