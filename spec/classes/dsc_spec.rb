require 'spec_helper'
require 'shared_contexts'

describe 'dsc' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #enable_collector: true,
      #enable_presenter: false,
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
      describe 'check default config' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it do
          is_expected.to compile.with_all_deps
        end
        it { is_expected.to contain_dsc__collector() }
        it { is_expected.to contain_dsc__params() }
        it { is_expected.to contain_dsc() }

      end

      describe 'Change Defaults' do
        context 'enable_collector' do
          before { params.merge!( enable_collector: false ) }
          it { is_expected.to compile }
          it { is_expected.to_not contain_dsc__collector() }
        end
        context 'enable_presenter' do
          before { params.merge!( enable_presenter: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
          # Add Check to validate change was successful
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'enable_collector' do
          before { params.merge!( enable_collector: 'foo' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'enable_presenter' do
          before { params.merge!( enable_presenter: 'foo' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
