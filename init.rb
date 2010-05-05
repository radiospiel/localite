require "rubygems"

gem_root = File.expand_path(File.dirname(__FILE__))

load "#{gem_root}/config/dependencies.rb"
load "#{gem_root}/lib/#{File.basename(gem_root)}.rb"

module Localite; end

require "#{gem_root}/lib/localite"
Localite.init
