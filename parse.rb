# This is a Puppet 2.6 'application' for the parsing functionality
# if you install this into your ruby libdir, something like:
#
#   /usr/lib/ruby/site_ruby/1.8/puppet/application/parse.rb
#
# You can just run:
#
#   puppet parse
#
# On any node, it takes the same --limit, --no-class and
# --no-tags options as the standalone
require 'puppet/application'

class Puppet::Application::Parse < Puppet::Application
    should_parse_config
    run_mode :parse

    attr_reader :limit, :notags, :noclasses

    def preinit
        options[:limit] = nil
        options[:notags] = false
        options[:noclasses] = false
    end

    option("--no-tags", "--nt") do |v|
        options[:notags] = true
    end

    option("--no-classes", "--nc") do |v|
        options[:noclasses] = true
    end

    option("--limit [TYPE]", "-l") do |v|
        options[:limit] = v
    end

    def setup
        Puppet.settings.use :main, :agent
    end

    def run_command
        lc = File.open("#{Puppet.settings[:clientyamldir]}/catalog/#{Facter.fqdn}.yaml")
        
        begin
          pup = Marshal.load(lc)
        rescue TypeError
          lc.rewind
          pup = YAML.load(lc)
        rescue Exception => e
          raise
        end

        printclasses(pup) unless options[:noclasses] == true
        printtags(pup) unless options[:notags] == true

        puts("Resources managed by puppet on this node:")
        printresource(pup)
    end

    def printresource(resource)
        if resource.class == Puppet::Resource::Catalog
            resource.edges.each do |b|
                printresource b
            end
        elsif resource.class == Puppet::Relationship and resource.target.class == Puppet::Resource and resource.target.title != nil and resource.target.file != nil
            target = resource.target
            manifestfile = target.file.gsub("/etc/puppet/manifests/", "")
    
            if options[:limit ]
                if target.type.downcase == options[:limit]
                    puts "\t#{target.type} { #{target.title}: }\n\t\tdefined in #{manifestfile}:#{target.line}\n\n"
                end
            else
                puts "\t#{target.type} { #{target.title}: }\n\t\tdefined in #{manifestfile}:#{target.line}\n\n"
            end
        end
    end

    def printtags(cat)
        puts("Tags for this node:")
        cat.tags.each do |tag|
            puts("\t#{tag}")
        end

        puts
    end

    def printclasses(cat)
        puts("Classes included on this node:")
        cat.classes.each do |klass|
            puts("\t#{klass}")
        end
        
        puts("\n\n")
    end
end
