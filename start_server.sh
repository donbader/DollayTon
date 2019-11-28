rm ./tmp/pids/server.pid

bundle install
rake db:migrate
bundle exec rails s -p 3000 -b '0.0.0.0'
