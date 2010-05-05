#
# The initializer for the gem. Runs whenever the gem is loaded.
#
# DON'T CHANGE THIS FILE, CHANGE config/gem.rb INSTEAD!
#

gem_root = File.expand_path(File.dirname(__FILE__))
gem_name = File.basename gem_root

require "rubygems"

load "#{gem_root}/config/gem.rb"
load "#{gem_root}/config/dependencies.rb"
load "#{gem_root}/lib/#{gem_name}.rb"
