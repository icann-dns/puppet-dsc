require 'beaker-rspec'

# Install Puppet on all hosts
hosts.each do |host|
  if host['platform'] =~ /freebsd/
    #default installs incorect version
    host.install_package('sysutils/puppet38')
    host.install_package('dns/bind-tools')
    #install_puppet_on(host)
  else
    install_puppet_on(host)
  end
end

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    # Install module to all hosts
    hosts.each do |host|
      install_dev_puppet_module_on(host, :source => module_root )
      # Install dependencies
      on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
    end
  end
end
