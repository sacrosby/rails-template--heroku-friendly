# template.rb
@template = @root + "/../master_template" # This is a big assumption, but I use it everywhere -- FIXME
@app = @root.split('/').last # new name of the app

# other templates
load_template "#{@template}/authlogic.template.rb"

# css framework prompt
css_framework = ask("What CSS Framework do you want to use with Compass? (default: '960')")
css_framework = "960" if css_framework.blank?

# sass storage prompt
sass_dir = ask("Where would you like to keep your sass files within your project? (default: 'app/stylesheets')")
sass_dir = "app/stylesheets" if sass_dir.blank?

# compiled css storage prompt
css_dir = ask("Where would you like Compass to store your compiled css files? (default: 'public/stylesheets')")
css_dir = "public/stylesheets" if css_dir.blank?

# gems
gem "haml"
gem 'sqlite3-ruby', :lib => 'sqlite3'
gem "compass", :version => ">= 0.8.17"
rake('gems:install', :sudo => true)
rake "gems:unpack GEM=compass"
run "haml --rails #{@root}"

# load any compass framework plugins
if css_framework =~ /960/
  gem "compass-960-plugin", :lib => "ninesixty"
  rake "gems:install GEM=compass-960-plugin"
  css_framework = "960" # rename for command
  plugin_require = "-r ninesixty"
end

# build out compass command
compass_command = "compass --rails -f #{css_framework} . --css-dir=#{css_dir} --sass-dir=#{sass_dir} "
compass_command << plugin_require if plugin_require

# Require compass during plugin loading
file 'vendor/plugins/compass/init.rb', <<-CODE
# This is here to make sure that the right version of sass gets loaded (haml 2.2) by the compass requires.
require 'compass'
CODE

# integrate it!
run compass_command
run "script/plugin install git://github.com/heroku/sass_on_heroku.git"
puts "Compass (with #{css_framework}) is all setup, have fun!"

# remove cruft
run "rm public/index.html"
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm -f public/javascripts/*"
run "rm -f public/images/*"

# add jquery helpers in application.js
run "cp #{@template}/application.js public/javascripts/application.js"

# add reset.css
run "cp #{@template}/reset.css public/stylesheets/reset.css"

# application.haml layout
run "cp #{@template}/application.haml app/views/layouts/application.haml"

# create sample data w users
run "cp #{@template}/users.yml test/fixtures/users.yml"

# # create mkdb script and run it
# run "cp #{@template}/mkdb script/mkdb; chmod +x script/mkdb; ./script/mkdb"

# new repo
git :init

rake "db:migrate"

file ".gems", <<-END
compass-960-plugin
compass --version '>= 0.8.17'
haml --version '>= 2.2.3'
RedCloth --version 4.1.9
authlogic --version 2.1.3
cancan --version 1.0.1
END

# Set up .gitignore files
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}

file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
*.psd
END

git :add => "."
git :commit => "-a -m 'Initial commit'"

# finish
puts "--- Template Finished ---"
