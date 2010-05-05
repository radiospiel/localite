#
# set up fake rails

require "active_record"
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
