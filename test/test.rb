#!/usr/bin/env ruby
DIRNAME = File.expand_path File.dirname(__FILE__)
Dir.chdir(DIRNAME)

#
# initialize the gem and the test runner
require '../init'

require 'logger'
require 'ruby-debug'

require "#{DIRNAME}/initializers/fake_rails.rb"
require "#{DIRNAME}/initializers/active_record.rb"

I18n.load_path += Dir["#{DIRNAME}/i18n/*.yml"]

# ---------------------------------------------------------------------

begin
  require 'minitest-rg'
rescue MissingSourceFile
  STDERR.puts "'gem install minitest-rg' gives you redgreen minitests"
  require 'minitest/unit'
end

#
# run tests

require "etest"

Etest.autorun
