What is this?
=============
A puppet face that reads catalogs from Puppet and displays the contents.

Usage
=====
<pre>
# puppet catalog print
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

R.I.Pienaar / rip@devco.net / @ripienaar / http://devco.net/
