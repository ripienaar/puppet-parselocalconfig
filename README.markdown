What is this?
=============
A script that reads catalogs from Puppet versions 0.24, 0.25 and 2.6
and displays the contents.

Usage
=====
<pre>
# parselocalconfig.rb /var/lib/puppet/client_yaml/catalog/fqdn.yaml
Classes included on this node:
        fqdn
        common::linux
        <snip>
 
Tags for this node:
        fqdn
        common::linux
        <snip>
 
Resources managed by puppet on this node:
        yumrepo{centos-base: }
                defined in common/modules/yum/manifests/init.pp:24
 
        file{/root/.ssh: }
                defined in common/modules/users/manifests/root.pp:20
 
        <snip>
</pre>

Various options exist to limit the output:

<pre>
   --limit [TYPE] - only shows resources of TYPE like Package
   --no-classes   - don't show any classes
   --no-tags      - don't show any tags
   --help         - shows help
</pre>

Contact
=======
You can contact me on rip@devco.net or follow my blog at www.devco.net
I am also on twitter as ripienaar
