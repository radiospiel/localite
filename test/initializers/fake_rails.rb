#
# set up fake rails

require "rubygems"
gem "activerecord", '~> 2.3'
gem "activesupport", '~> 2.3'

require "active_support"
require "fileutils"

LOGFILE = "log/test.log"
SQLITE_FILE = ":memory:"

#
# -- set up fake rails ------------------------------------------------

RAILS_ENV="test"
RAILS_ROOT="#{DIRNAME}"

if !defined?(RAILS_DEFAULT_LOGGER)
  FileUtils.mkdir_p File.dirname(LOGFILE)
  RAILS_DEFAULT_LOGGER = Logger.new(LOGFILE)
  RAILS_DEFAULT_LOGGER.level = Logger::DEBUG
end
