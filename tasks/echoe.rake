#
# GEM settings
#
GEM_ROOT = File.expand_path("#{File.dirname(__FILE__)}/..")

if gem_config = YAML.load(File.read("#{GEM_ROOT}/config/gem.yml"))
  require 'echoe'  

  #
  # a dependency reader
  module Dependency
    @@dependencies = []

    def self.require(file)
      @@dependencies << file
    end

    def self.load
      eval File.read("#{GEM_ROOT}/config/dependencies.rb"), binding
      @@dependencies
    end
  end

  Echoe.new(File.basename(GEM_ROOT), File.read("#{GEM_ROOT}/VERSION")) do |p|  
    gem_config.each do |k,v|
      p.send "#{k}=",v
    end
    
    p.runtime_dependencies = Dependency.load
  end

  desc "Rebuild and install the gem"
  task :rebuild => %w(manifest default build_gemspec package) do
    gem = Dir.glob("pkg/*.gem").sort_by do |filename|
      File.new(filename).mtime
    end.last

    puts "============================================="
    puts "Installing gem..."

    system "gem install #{gem} > /dev/null 2>&1"

    puts ""
    puts "I built and installed the gem for you. To upload, run "
    puts
    puts "    gem push #{gem}"
  end
end
