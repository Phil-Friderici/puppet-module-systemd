require 'spec_helper'

describe 'systemd::unit', type: :define do
  let(:title) { 'unittest' }

  # for OS independent tests we use a supported RedHat version
  redhat = {
    supported_os: [
      {
        'operatingsystem'        => 'RedHat',
        'operatingsystemrelease' => ['7'],
      },
    ],
  }

  content = <<-END.gsub(%r{^\s+\|}, '')
    |[Unit]
    |
    |[Service]
    |Type=simple
    |
    |[Install]
  END

  on_supported_os.sort.each do |os, facts|
    describe "on #{os} with defaults" do
      let(:facts) { facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('systemd') }
      it { is_expected.to have_systemd__unit_resource_count(1) }
      it do
        is_expected.to contain_file('unittest_file').with(
          {
            'ensure'  => 'present',
            'path'    => '/etc/systemd/system/unittest.service',
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0644',
            'content' => content,
          },
        )
      end

      it do
        is_expected.to contain_service('unittest_service').with(
          {
            'ensure'    => 'running',
            'name'      => 'unittest',
            'enable'    => true,
            'provider'  => 'systemd'
          },
        )
      end

      it { is_expected.to contain_exec('systemd_reload') } # only here to reach 100% resource coverage
    end

    describe "on #{os} with all parameters set" do
      let(:params) do
        {
          'ensure'                  => 'present',
          'systemd_path'            => '/tmp/systemd',
          'unit_after'              => 'test',
          'unit_before'             => 'test2',
          'unit_description'        => 'Example unit',
          'unit_requires'           => 'test3',
          'environment'             => 'TEST=test',
          'group'                   => 'testgroup',
          'user'                    => 'testuser',
          'workingdirectory'        => '/tmp/workdir',
          'service_type'            => 'oneshot',
          'service_timeoutstartsec' => '6',
          'service_restart'         => 'testrestart',
          'service_restartsec'      => '6',
          'service_execstartpre'    => ['/bin/uname'],
          'service_execstart'       => '/bin/echo',
          'service_execstop'        => '/bin/true',
          'install_wantedby'        => 'multi-user.target',
        }
      end

      content_full = <<-END.gsub(%r{^\s+\|}, '')
        |[Unit]
        |Description=Example unit
        |After=test
        |Before=test2
        |Requires=test3
        |
        |[Service]
        |Type=oneshot
        |TimeoutStartSec=6
        |Restart=testrestart
        |RestartSec=6
        |WorkingDirectory=/tmp/workdir
        |Environment="TEST=test"
        |User=testuser
        |Group=testgroup
        |ExecStartPre=/bin/uname
        |ExecStart=/bin/echo
        |ExecStop=/bin/true
        |
        |[Install]
        |WantedBy=multi-user.target
      END

      it { is_expected.to contain_file('unittest_file').with_content(content_full) }
    end
  end

  on_supported_os(redhat).sort.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with ensure set to valid value' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to contain_file('unittest_file').with_ensure('absent') }
      end

      context 'with systemd_path set to valid value' do
        let(:params) { { systemd_path: '/test/ing' } }

        it { is_expected.to contain_file('unittest_file').with_path('/test/ing/unittest.service') }
      end

      context 'with unit_after set to valid value' do
        let(:params) { { unit_after: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^After=testing$}) }
      end

      context 'with unit_before set to valid value' do
        let(:params) { { unit_before: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Before=testing$}) }
      end

      context 'with unit_description set to valid value' do
        let(:params) { { unit_description: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Description=testing$}) }
      end

      context 'with unit_requires set to valid value' do
        let(:params) { { unit_requires: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Requires=testing$}) }
      end

      context 'with environment set to valid value' do
        let(:params) { { environment: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Environment="testing"$}) }
      end

      context 'with group set to valid value' do
        let(:params) { { group: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Group=testing$}) }
      end

      context 'with user set to valid value' do
        let(:params) { { user: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^User=testing$}) }
      end

      context 'with service_type set to valid value' do
        let(:params) { { service_type: 'oneshot' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Type=oneshot$}) }
      end

      context 'with workingdirectory set to valid value' do
        let(:params) { { workingdirectory: '/test/ing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^WorkingDirectory=/test/ing$}) }
      end

      context 'with service_timeoutstartsec set to valid value' do
        let(:params) { { service_timeoutstartsec: '2min 42sec' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^TimeoutStartSec=2min 42sec$}) }
      end

      context 'with service_restart set to valid value' do
        let(:params) { { service_restart: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^Restart=testing$}) }
      end

      context 'with service_restartsec set to valid value' do
        let(:params) { { service_restartsec: '2min 42sec' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^RestartSec=2min 42sec$}) }
      end

      context 'with service_execstartpre set to valid array' do
        let(:params) { { service_execstartpre: ['test', 'ing'] } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^ExecStartPre=test\nExecStartPre=ing$}) }
      end

      context 'with service_execstart set to valid value' do
        let(:params) { { service_execstart: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^ExecStart=testing$}) }
      end

      context 'with service_execstop set to valid value' do
        let(:params) { { service_execstop: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^ExecStop=testing$}) }
      end

      context 'with install_wantedby set to valid value' do
        let(:params) { { install_wantedby: 'testing' } }

        it { is_expected.to contain_file('unittest_file').with_content(%r{^WantedBy=testing$}) }
      end
    end
  end

  on_supported_os(redhat).sort.each do |_os, os_facts|
    context 'variable type and content validations' do
      let(:facts) { os_facts }

      validations = {
        'Stdlib::Absolutepath' => {
          name:    ['systemd_path'],
          valid:   ['/absolute/filepath', '/absolute/directory/'],
          invalid: ['./relative/path', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, nil],
          message: 'expects a Stdlib::Absolutepath',
        },
        'Optional[Array]' => {
          name:    ['service_execstartpre'],
          valid:   [['array']],
          invalid: ['string', { 'ha' => 'sh' }, 3, 2.42, true],
          message: 'expects a value of type Undef or Array',
        },
        'Optional[Systemd::Sec]' => {
          name:    ['service_timeoutstartsec', 'service_restartsec'],
          valid:   [242, '242', '1ms', '1s', '1sec', '1m', '1min', '1h', '1hour', '1min 10s', '1m 10sec'],
          invalid: [['array'], { 'ha' => 'sh' }, true, -242, '-242', 2.42],
          message: '(Systemd::Sec|)', # unkown error message for '-242' :(
        },
        'Optional[String[1]]' => {
          name:    ['unit_after', 'unit_before', 'unit_description', 'environment', 'group', 'user', 'workingdirectory', 'service_restart',
                    'service_execstart', 'service_execstop', 'install_wantedby'],
          valid:   ['valid'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
          message: 'expects a value of type Undef or String',
        },
        'Enum[present, absent]' => {
          name:    ['ensure'],
          valid:   ['present', 'absent'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
          message: 'expects a match for Enum\[\'absent\', \'present\'\]',
        },
        'Systemd::Service_type' => {
          name:    ['service_type'],
          valid:   ['simple', 'forking', 'oneshot', 'dbus', 'notify', 'idle'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true],
          message: 'Systemd::Service_type',
        },
      }
      validations.sort.each do |type, var|
        var[:name].each do |var_name|
          var[:params] = {} if var[:params].nil?
          var[:valid].each do |valid|
            context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
              let(:params) { [var[:params], { "#{var_name}": valid, }].reduce(:merge) }

              it { is_expected.to compile }
            end
          end

          var[:invalid].each do |invalid|
            context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
              let(:params) { [var[:params], { "#{var_name}": invalid, }].reduce(:merge) }

              it 'fail' do
                expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
              end
            end
          end
        end
      end
    end
  end
end
