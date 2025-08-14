# frozen_string_literal: true

require 'spec_helper'

describe 'tinyproxy' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      # below is a list of the resource parameters that you can override.
      # By default all non-required parameters are commented out,
      # while all required parameters will require you to add a value
      describe 'check default parameters' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it do
          is_expected.to compile.with_all_deps
        end

        it { is_expected.to contain_package('tinyproxy') }
        it { is_expected.to contain_class('tinyproxy') }

        it do
          is_expected.to contain_file('/etc/tinyproxy/tinyproxy.conf').with(
            ensure: 'file',
            notify: 'Service[tinyproxy]',
          ).
          with_content(%r{^Listen 0.0.0.0}).
          with_content(%r{^Port 8888}).
          with_content(%r{^User tinyproxy}).
          with_content(%r{^Group tinyproxy}).
          with_content(%r{^Timeout 600}).
          with_content(%r{^MaxClients 100}).
          with_content(%r{^MinSpareServers 5}).
          with_content(%r{^MaxSpareServers 20}).
          with_content(%r{^StartServers 10}).
          with_content(%r{^Syslog On}).
          with_content(%r{^LogLevel Warning}).
          with_content(%r{^DefaultErrorFile /usr/share/tinyproxy/default.html}).
          with_content(%r{^PidFile /run/tinyproxy/tinyproxy.pid}).
          with_content(%r{^StatFile /usr/share/tinyproxy/stats.html}).
          with_content(%r{^ConnectPort 443})
        end

        it do
          is_expected.to contain_service('tinyproxy').with(
            enable: 'true',
            ensure: 'running'
          )
        end
      end
    end
  end
end
