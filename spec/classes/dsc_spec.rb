# frozen_string_literal: true

require 'spec_helper'

describe 'dsc' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:node) { 'foo.example.com' }
  let(:params) do
    {
      # prefix: "/usr/local/dsc",
      # ip_addresses: [],
      # custom_datasets: [],
      # bpf_program: false,
      # destinations: [],
      # listen_interfaces: [],
      # pid_file: "/var/run/dsc-statistics-collector/default/dsc.pid",
      # max_memory: 4194304,
      # presenter: "dsc",
    }
  end

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      case facts[:kernel]
      when 'FreeBSD'
        let(:package) { 'dsc-collector' }
        let(:conf_file) { '/usr/local/etc/dsc.conf' }
        let(:service) { 'dsc' }
      else
        let(:package) { 'dsc-statistics-collector' }
        let(:conf_file) { '/etc/dsc-statistics/dsc-collector.cfg' }
        let(:service) { 'dsc-statistics-collector' }
      end
      describe 'check default config' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it do
          is_expected.to compile.with_all_deps
        end

        it { is_expected.to contain_package(package) }
        it { is_expected.to contain_class('Dsc') }
        it { is_expected.to contain_class('Dsc::Params') }
        it do
          is_expected.to contain_file('/usr/local/dsc').with(
            'ensure' => 'directory',
            'mode'   => '0755'
          )
        end
        it do
          is_expected.to contain_file('/usr/local/dsc/run/').with(
            'ensure' => 'directory'
          )
        end
        it do
          is_expected.to contain_file('/usr/local/dsc/run/foo').with(
            'ensure' => 'directory'
          )
        end
        it do
          is_expected.to contain_file('/usr/local/dsc/run/foo/upload').with(
            'ensure' => 'directory'
          )
        end
        it do
          is_expected.to contain_file('/usr/local/dsc/run/foo/upload/dsp').with(
            'ensure' => 'directory'
          )
        end
        it do
          is_expected.to contain_file(conf_file).with(
            'ensure' => 'present'
          ).with_content(
            %r{run_dir "/usr/local/dsc/run/foo"}
          ).with_content(
            %r{pid_file "/var/run/dsc-statistics-collector/default/dsc.pid"}
          )
        end
        it do
          is_expected.to contain_file('/usr/local/bin/upload_prep').with(
            'ensure' => 'present',
            'mode' => '0755'
          ).with_content(
            %r{#{conf_file}}
          )
        end
        it do
          is_expected.to contain_service(service).with(
            'enable' => 'true',
            'ensure' => 'running'
          )
        end
        it do
          is_expected.to contain_cron('upload_prep').with(
            'command' => '/usr/bin/flock -n /var/lock/upload_prep.lock /usr/local/bin/upload_prep',
            'ensure' => 'present',
            'minute' => '*/5',
            'user' => 'root'
          )
        end
        if facts[:kernel] == 'FreeBSD'
          it { is_expected.to contain_package('devel/p5-Proc-PID-File') }
          it do
            is_expected.to contain_file("/usr/local/etc/rc.d/#{service}").with(
              'before' => "Service[#{service}]",
              'ensure' => 'present',
              'mode' => '0555'
            ).with_content(
              %r{command_args="-p #{conf_file}}
            ).with_content(
              %r{pidfile=/var/run/dsc-statistics-collector/default/dsc.pid}
            )
          end
        else
          it do
            is_expected.to contain_file(
              '/etc/cron.d/dsc-statistics-collector'
            ).with_ensure('absent')
          end
          if facts[:lsbdistcodename] == 'trusty'
            it do
              is_expected.to contain_file(
                '/etc/init.d/dsc-statistics-collector'
              ).with_content('echo "Use upstart"')
            end
            it do
              is_expected.to contain_file(
                '/etc/init/dsc-statistics-collector.conf'
              ).with(
                'before' => "Service[#{service}]"
              ).with_content(
                %r{limit rss 4194304 4194304}
              ).with_content(
                %r{exec \/usr\/bin\/dsc -f -p #{conf_file}}
              )
            end
          else
            it do
              is_expected.to contain_file(
                "/lib/systemd/system/#{service}.service"
              ).with(
                'before' => "Service[#{service}]"
              ).with_content(
                %r{ExecStart=/usr/bin/dsc -f -p /etc/dsc-statistics/dsc-collector.cfg}
              )
            end
          end
        end
      end

      describe 'Change Defaults' do
        context 'prefix' do
          before { params.merge!(prefix: '/usr/local/foo') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/usr/local/foo').with(
              'ensure' => 'directory',
              'mode' => '0755'
            )
          end
          it do
            is_expected.to contain_file('/usr/local/foo/run/').with(
              'ensure' => 'directory'
            )
          end
          it do
            is_expected.to contain_file('/usr/local/foo/run/foo').with(
              'ensure' => 'directory'
            )
          end
          it do
            is_expected.to contain_file('/usr/local/foo/run/foo/upload').with(
              'ensure' => 'directory'
            )
          end
          it do
            is_expected.to contain_file('/usr/local/foo/run/foo/upload/dsp').with(
              'ensure' => 'directory'
            )
          end
        end
        context 'ip_addresses' do
          before { params.merge!(ip_addresses: ['192.0.2.1']) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'bpf_program' do
          before { params.merge!(bpf_program: true) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'listen_interfaces' do
          before { params.merge!(listen_interfaces: ['bla0']) }
          it { is_expected.to compile }
        end
        context 'custom_dataset' do
          before { params.merge!(custom_dataset: ['qtype']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(conf_file).with(
              'ensure' => 'present'
            ).with_content(
              %r{dataset qtype}
            )
          end
        end
        context 'package' do
          before { params.merge!(package: 'foo') }
          it { is_expected.to compile }
          it { is_expected.to contain_package('foo') }
        end
        context 'conf_file' do
          before { params.merge!(conf_file: '/etc/foo.conf') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/foo.conf').with(
              'ensure' => 'present'
            )
          end
        end
        context 'service' do
          before { params.merge!(service: 'foo') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_service('foo').with(
              'enable' => 'true',
              'ensure' => 'running'
            )
          end
          if facts[:kernel] == 'Linux'
            if facts[:lsbdistcodename] == 'trusty'
              it { is_expected.to contain_file('/etc/init/foo.conf') }
            else
              it { is_expected.to contain_file('/lib/systemd/system/foo.service') }
            end
          else
            it { is_expected.to contain_file('/usr/local/etc/rc.d/foo') }
          end
        end
        context 'pid_file' do
          before { params.merge!(pid_file: '/foo.pid') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(conf_file).with(
              'ensure' => 'present'
            ).with_content(
              %r{run_dir "/usr/local/dsc/run/foo"}
            ).with_content(
              %r{pid_file "/foo.pid"}
            )
          end
          if facts[:kernel] == 'FreeBSD'
            it { is_expected.to contain_package('devel/p5-Proc-PID-File') }
            it do
              is_expected.to contain_file(
                "/usr/local/etc/rc.d/#{service}"
              ).with_content(
                %r{pidfile=/foo.pid}
              )
            end
          end
        end
        if facts[:kernel] == 'Linux' && facts[:lsbdistcodename] == 'trusty'
          context 'max_memory' do
            before { params.merge!(max_memory: 1024) }
            it { is_expected.to compile }
            it do
              is_expected.to contain_file(
                '/etc/init/dsc-statistics-collector.conf'
              ).with(
                'before' => "Service[#{service}]"
              ).with_content(
                %r{limit rss 1024 1024}
              ).with_content(
                %r{exec /usr/bin/dsc -f -p #{conf_file}}
              )
            end
          end
        end
        context 'presenter' do
          before { params.merge!(presenter: 'hedgehog') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/dsc/run/foo/upload/hedgehog'
            ).with('ensure' => 'directory')
          end
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'prefix' do
          before { params.merge!(prefix: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          before { params.merge!(ip_addresses: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'bpf_program' do
          before { params.merge!(bpf_program: 'foo') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'listen_interfaces' do
          before { params.merge!(listen_interfaces: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'custom_dataset' do
          before { params.merge!(custom_dataset: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'package' do
          before { params.merge!(package: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'conf_file' do
          before { params.merge!(conf_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'service' do
          before { params.merge!(service: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'pid_file' do
          before { params.merge!(pid_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'max_memory' do
          before { params.merge!(max_memory: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'presenter bad type' do
          before { params.merge!(presenter: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'presenter bad option' do
          before { params.merge!(presenter: 'foo') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
