require 'puppet/face'

Puppet::Face.define(:catalog, '0.0.1') do
  action :print do
    summary "Displays the contents of a catalog"

    option "--catalog CATALOG" do
      summary "Path to a specific catalog to print"
    end

    option "--limit TYPE" do
      summary "Limits the display to a certain type"
    end

    option "--no-classes" do
      summary "Do not show any classes"
    end

    option "--no-resources" do
      summary "Do not show resources list"
    end

    option "--no-tags" do
      summary "Do not show any tags"
    end


    when_invoked do |options|
      Puppet.settings.preferred_run_mode = "agent"

      catalog_file = options.fetch(:catalog, File.join([Puppet[:client_datadir], "catalog", "%s.json" % Puppet[:certname]]))

      catalog = PSON.parse(File.read(catalog_file))

      unless options[:no_classes] == false
        puts("Classes included on this node:")
        catalog.classes.each do |klass|
          puts("\t#{klass}")
        end

        puts("\n\n")
      end

      unless options[:no_tags] == false
        puts("Tags for this node:")
        catalog.tags.each do |tag|
          puts("\t#{tag}")
        end

        puts("\n\n")
      end

      unless options[:no_resources] == false
        puts("Resources managed by puppet on this node:")
        printresource(catalog, options[:limit])
      end

      nil
    end
  end

  def printresource(resource, limit)
    if resource.class == Puppet::Resource::Catalog
      resource.edges.each do |b|
        printresource(b, limit)
      end
    elsif resource.class == Puppet::Relationship and resource.target.class == Puppet::Resource and resource.target.title != nil and resource.target.file != nil
      target = resource.target
      manifestfile = target.file.gsub("/etc/puppet/manifests/", "")

      if limit
        if target.type.downcase == limit.downcase
          puts "\t#{target.type} { #{target.title}: }\n\t\tdefined in #{manifestfile}:#{target.line}\n\n"
        end
      else
          puts "\t#{target.type} { #{target.title}: }\n\t\tdefined in #{manifestfile}:#{target.line}\n\n"
      end
    end
  end
end
