### Setup databases

Assuming you already installed [neo4j](https://github.com/neo4jrb/neo4j) and [RSpec](https://github.com/rspec/rspec-rails), at first we have to install a separate database for our tests.

    rake neo4j:install[community-2.1.5,development]  #development database
    rake neo4j:install[community-2.1.5,test]         #test database

By default both databases will try to start on the same port so we should change configuration of the test database to resolve the conflict.

    rake neo4j:config[test,7475]  #port 7475

Then go to the test environment file and add these lines to your configuration files:

config/environments/test.rb

    config.neo4j.session_type = :server_db
    config.neo4j.session_path = 'http://localhost:7475'

Now we should be able to start both databases simultaneously by running:

    rake neo4j:start[development]
    rake neo4j:start[test]

### Setup database cleaner

I recently pushed basic neo4j support to the [database cleaner](https://github.com/DatabaseCleaner/database_cleaner) gem. So we have to install the version from the master branch.
Add to your Gemfile:

Gemfile

~~~ruby
  gem 'database_cleaner', github: 'DatabaseCleaner/database_cleaner'
~~~

and install it.

    bundle install

To integrate it with RSpec open the rails_helper file and require database cleaner and all your models above the configuration block:

spec/rails_helper.rb

~~~ruby
require 'database_cleaner'
Dir["#{Rails.root}/app/models/**/*.rb"].each do |model|
  load model
end
~~~

You have to preload models if you use transaction strategy which is default for neo4j. Deletion strategy does not require preloading.

Then add into the configuration block these lines:

spec/rails_helper.rb

~~~ruby
RSpec.configure do |config|
  #...
  DatabaseCleaner[:neo4j, connection: {type: :server_db, path: 'http://localhost:7475'}].strategy = :transaction  #for transaction strategy
 #DatabaseCleaner[:neo4j, connection: {type: :server_db, path: 'http://localhost:7475'}].strategy = :deletion     #for deletion strategy

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
~~~

That's it. I hope it was easy enough.







