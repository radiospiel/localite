#!/usr/bin/env ruby
DIRNAME = File.expand_path File.dirname(__FILE__)
Dir.chdir(DIRNAME)

ETEST_TEST=true

#
# initialize the gem and the test runner
require '../init'

require 'logger'
require 'ruby-debug'

require "#{DIRNAME}/initializers/fake_rails.rb"
require "#{DIRNAME}/initializers/active_record.rb"

# ---------------------------------------------------------------------

begin
  require 'minitest-rg'
rescue MissingSourceFile
  STDERR.puts "'gem install minitest-rg' gives you redgreen minitests"
  require 'minitest/unit'
end

#
# run tests

Etest.autorun if defined?(Etest)
MiniTest::Unit.autorun
