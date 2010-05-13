#!/usr/bin/ruby

# Reads the puppet YAML cache and prints out all the resources in it
# for each resource it will show the file it was defined in on the 
# master
#
# Simply pass in the path to the yaml file
#
# History:
# 2009/07/30 - Initial Release
# 2010/02/26 - Add 0.25 Support
# 2010/03/01 - Add options to load a new config file, limit resources
#              and some 0.24 and 0.25 improvements for guessing where
#              to find the yaml
# 2010/03/30 - Improves Puppet 0.25 support thanks to Andy Asquelt
#
# Contact:
# R.I.Pienaar <rip@devco.net> - www.devco.net - @ripienaar

# fool it into giving me the right config later on so I can guess
# about the location of localconfig.yaml as the puppetd would see things
$0 = "puppetd"

require 'puppet'
require 'yaml'
require 'optparse'
require 'facter'
require 'pp'

@limit = nil

OptionParser.new do |opt|
  opt.banner = "Usage: #{__FILE__} [options] [yaml file]"

  opt.on("--config [FILE]", "-c", "Config file") do |v|
    Puppet[:config] = v
  end

  opt.on("--limit [TYPE]", "-l", "Limit to resources of type") do |v|
    @limit = v
  end

  opt.on("--no-classes", "--nc", "Don't show classes list") do |v|
    @noclasses = true
  end

  opt.on("--no-tags", "--nt", "Don't show tags list") do |v|
    @notags = true
  end

  opt.on("--help", "-h", "Help") do |v|
    puts opt
    exit
  end
end.parse!

Puppet[:name] = "puppetd"

Puppet.parse_config

if Puppet.version =~ /^[0-9]+[.]([0-9]+)[.][0-9]+$/
  version = $1.to_i

  unless version == 25 || version == 24
    puts("Don't know how to print catalogs for verion #{Puppet.version} only 0.24 and 0.25 is supported")
    exit 1
  end
else
  puts("Could not figure out version from #{Puppet.version}")
  exit 1
end

# Navigate the hellish mess of changing behaviour 24 v 25
case version
  when  24
    ARGV[0] ? localconfig = ARGV[0] : localconfig = "#{Puppet[:localconfig]}.yaml"

  when 25
    facts = Facter.to_hash
    fqdn = facts['fqdn']

    ARGV[0] ? localconfig = ARGV[0] : localconfig = "#{Puppet[:clientyamldir]}/catalog/#{fqdn}.yaml"
end

unless File.exist?(localconfig)
  puts("Can't figure out where the localconfig yaml file is, please specify a path")
  exit 1
end

lc = File.open(localconfig)

begin
  pup = Marshal.load(lc)
rescue TypeError
  lc.rewind
  pup = YAML.load(lc)
rescue Exception => e
  raise
end

def printbucket(bucket)
  if bucket.class == Puppet::TransBucket
    bucket.each do |b|
      printbucket b
    end
  elsif bucket.class == Puppet::TransObject
    manifestfile = bucket.file.gsub("/etc/puppet/manifests/", "")

    if @limit 
      if bucket.type == @limit
        puts "\t#{bucket.type} { #{bucket.name}: }\n\t\tdefined in #{manifestfile}:#{bucket.line}\n\n"
      end
    else
        puts "\t#{bucket.type} { #{bucket.name}: }\n\t\tdefined in #{manifestfile}:#{bucket.line}\n\n"
    end
  end
end

def printresource(resource)
  if resource.class == Puppet::Resource::Catalog
    resource.edges.each do |b|
      printresource b
    end
  elsif resource.class == Puppet::Relationship and resource.target.class == Puppet::Resource and resource.target.title != nil and resource.target.file != nil
    target = resource.target
    manifestfile = target.file.gsub("/etc/puppet/manifests/", "")

    if @limit 
      if target.type == @limit
        puts "\t#{target.type} { #{target.title}: }\n\t\tdefined in #{manifestfile}:#{target.line}\n\n"
      end
    else
        puts "\t#{target.type} { #{target.title}: }\n\t\tdefined in #{manifestfile}:#{target.line}\n\n"
    end
  end
end

unless @noclasses
  puts("Classes included on this node:")
  pup.classes.each do |klass|
    puts("\t#{klass}")
  end

  puts("\n\n")
end

if version == 25 && @notags != true
  # 0.24 doesn't have tags in it
  if pup.respond_to?("tags")
    puts("Tags for this node:")
    pup.tags.each do |tag|
      puts("\t#{tag}")
    end
  end

  puts("\n\n")
end

puts("Resources managed by puppet on this node:")
if version == 24
  printbucket pup
elsif version == 25
  printresource pup
else
  puts("Don't know how to print catelog for version #{version}")
end
