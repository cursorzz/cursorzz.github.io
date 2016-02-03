---
layout: page
title: "how to deploy rails project to digital ocean using mina"
date: 2016-02-03
summary: |
tags: rails deploy digital_ocean mina
---

# Server configuration
---
### create deploy user

```shell
useradd -m deploy
passwd deploy
```

```shell
chsh -s /bin/bash user
```
reference: [users and groups](https://wiki.archlinux.org/index.php/users_and_groups)

### create ssh keys for easier access

1. create key pairs on client
```bash
ssh-keygen -t rsa
```

2. upload public key to server
```bash
cat ~/.ssh/id_rsa.pub | ssh user@123.45.56.78 "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
```
reference: [ssh keys](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)



### setup ElasticSearch

```bash
sudo apt-get update
sudo apt-get install openjdk-7-jre-headless -y

wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.0.deb
sudo dpkg -i elasticsearch-1.3.2.deb
```

* uninstall via DEB
```bash
sudo dpkg -r DEB_PACKAGE
```

```bash
### NOT starting elasticsearch by default on bootup, please execute
 sudo update-rc.d elasticsearch defaults 95 10
### In order to start elasticsearch, execute
 sudo /etc/init.d/elasticsearch start
```
# Mina deployment
---
### mina config
first add mina and related gems to `Gemfile` and `bundle install`

```ruby
group :development do
  gem 'mina'
  gem 'mina-puma', :require => false
  gem 'mina-nginx', :require => false
  gem 'mina-multistage', require: false
end
```
then we initialize an deploy config file by:
```bash
mina init
```
this will generate config/deploy.rb

next we need add addons to deploy file, like below:
```ruby
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/nginx'
require 'mina/puma'
require 'mina/multistage'
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

# set :domain, '128.199.78.104'
# set :deploy_to, '/home/deploy-dev/tenderchase'
# set :repository, 'git@github.com:STCpl/tenderchase.git'
# set :branch, 'feature/deploy_to_DO_development_server'
# set :application, 'current'
#
set :application, 'current'

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log', 'tmp/pids', 'tmp/sockets']


# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]

  ## add tmp to shared
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/sockets"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/pids"]

  if repository
    repo_host = repository.split(%r{@|://}).last.split(%r{:|\/}).first
    repo_port = /:([0-9]+)/.match(repository) && /:([0-9]+)/.match(repository)[1] || '22'

    queue %[
      if ! ssh-keygen -H  -F #{repo_host} &>/dev/null; then
        ssh-keyscan -t rsa -p #{repo_port} -H #{repo_host} >> ~/.ssh/known_hosts
      fi
    ]
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    # queue! %[source ~/.bashrc && cat ~/.bashrc && echo $APP_DATABASE_PASSWORD]
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
      invoke :'puma:start'
      # invoke :'puma:phased_restart'
      # invoke :'nginx:restart'
    end
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
```

and by using [`mina-multistage`](https://github.com/endoze/mina-multistage) gem, we can seperate staging/production config. first init them:

```bash
mina multistage:init
```

this will create config/deploy/staging.rb and config/deploy/production.rb

and we can put user sensitive information in those files, for example in staging config file:

```ruby
# config/deploy/staging.rb
set :domain, '<your-server-ip>'
set :deploy_to, '<folder where your project locate>'
set :repository, '<git repo>'
set :branch, 'develop'
set :user, 'deploy-dev'
set :rails_env, "development"  # by default it's production
```

### deploy process
Let's take *staging* deploy process for example
First we use mina to setup all folders and links in our server

```bash
mina staging setup
```

Then we deploy code to server by running
```bash
mina staging deploy
```
you may encounter deploy errors when deploy

#### db:migration error

  this happens beacuse we dont configure the database info yet, notice that in previous mina setup step a shared folder was created in /<your home>/<app folder>/shared/config, and in there are **database.yml** and **secrets**. we need to configure them correctly

  here is an example for database.yml

```yml
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see rails configuration guide
  # http://guides.rubyonrails.org/configuring.html#database-pooling
  pool: 5
  host: localhost
  username: rails
  password: <%= ENV['APP_DATABASE_PASSWORD'] %>

development:
  <<: *default
  database: tenderchase_development
  
production:
  <<: *default
  database: tenderchase_production
  username: rails
  password: <%= ENV['APP_DATABASE_PASSWORD'] %>
```
APP_DATABASE_PASSWORD can be set in your bashrc file, **please notice that if you do this, you need put export env to the top of the bashrc file** 
see [mina issue](http://stackoverflow.com/a/33014007) for more details

---
#### no secrets error
you may also encounter no secret error, that means you have to generate an unique secret on your server and keep it in private

here is an example for secret file on server

```ruby
production:
  secret_key_base: <%= ENV['APP_SECRET']>
```
generate secret and export the secret as environment variable

```bash
echo "export APP_SECRET=$(rake secret)"
```

### Puma control

If deploy command running without any error, an app server should be up and running, here we use puma as the app server, the code we use to start a puma server is lay in code below:
```ruby
to :launch do
  queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
  queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
  invoke :'puma:start'    # <========
  # invoke :'puma:phased_restart'
end
```
there are other options to control puma, see [mina-puma](https://github.com/sandelius/mina-puma) for details. please be caution that all puma related command should has <environment> in between when you run from shell. for example if you want to stop puma in dev server, run `mina staging puma:stop`

### ngnix config and service control
now app server is running! Now we need a proxy to hidden it from scary internet! 

puma socket is located at `/<home>/<project-dir>/shared/tmp/sockets/puma.sock`, so we need to configure nginx at point to this sock

```nginx
pstream app_server {
    server unix:/<project-root>/shared/tmp/sockets/puma.sock fail_timeout=0;
}

server {
    listen   4000;
    root /<project-root>/current/public;
    server_name _;
    index index.htm index.html;

    location / {
            try_files $uri/index.html $uri.html $uri @app;
    }

    location ~* ^.+\.(jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|pdf|ppt|txt|tar|mid|midi|wav|bmp|rtf|mp3|flv|mpeg|avi)$ {
                    try_files $uri @app;
            }

     location @app {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_pass http://app_server;
    }
}
```
once we finish. we can use `mina <env> nginx:start` to start nginx from server. also there are some more handy command for [mina-nginx](https://github.com/hbin/mina-nginx)
