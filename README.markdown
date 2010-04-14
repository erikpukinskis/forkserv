### Introduction

ForkServ is a RESTful http-based front end for Git.  It lets you do things like this:

        POST /repos          
        # returns JSON {'success': true, 'id': 251}

        POST /repos/251/files/app.rb {'content': 'puts "hello, world!"}
        # saves app.rb and returns {'success': true}

        POST /repos/commits {'message': 'prints out a hello'}
        # saves app.rb and returns {'success': true, 'commit': '35665e8971925d42b179e70f284eb99feed18354'}

### Why

It's nice for web-based IDEs to use for hosting code.  It can act as a storage layer for
apps like [EasyFork](http://github.com/erikpukinskis/easyfork).  It makes it so those apps
don't have to worry about code storage or managing a revision history.

### Running a server

These instructions are for a basic Fedora Core 8 Amazon EC2 instance (AMI Id: ami-84db39ed).
But it shouldn't be terribly different for other setups.

1. Launch the instance.  Make sure port 80 is open
2. yum install git-core ruby-devel fcgi-devel fcgi-libs-devel gcc-c++ sqlite-devel
3. gem install rubygems-update
4. update_rubygems
5. gem install activerecord rest-client -v 1.3.0 
   heroku camping fcgi memcache-client builder hoe  
   sinatra grit test-spec fcgi mongrel shotgun rack-test 
   haml maruku erubis less ruby-debug sqlite3-ruby delayed_job
4. cd /opt
5. git clone http://github.com/erikpukinskis/forkserv.git
6. cd forkserv
7. mv config.yml.example config.yml
8. put your heroku username (email) and password in config.yml 
9. rackup config.ru
