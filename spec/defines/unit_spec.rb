require 'spec_helper'
describe 'systemd::unit' do
  let(:title) { 'spectest-unit' }

  # ensure that the class is passive by default
  describe 'with defaults for all parameters' do
    content = <<-END.gsub(%r{^\s+\|}, '')
      |[Unit]
      |
      |[Service]
      |Type=simple
      |
      |[Install]
    END

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to have_systemd__unit_resource_count(1) }
    it do
      is_expected.to contain_file('spectest-unit_file').with(
        {
          'ensure'  => 'present',
          'path'    => '/etc/systemd/system/spectest-unit.service',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          'content' => content,
        },
      )
    end

    it do
      is_expected.to contain_service('spectest-unit_service').with(
        {
          'ensure'    => 'running',
          'name'      => 'spectest-unit',
          'enable'    => true,
          'provider'  => 'systemd'
        },
      )
    end
  end

  describe 'with all parameters set' do
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

    content = <<-END.gsub(%r{^\s+\|}, '')
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

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to have_systemd__unit_resource_count(1) }

    it do
      is_expected.to contain_file('spectest-unit_file').with(
        {
          'ensure'  => 'present',
          'path'    => '/tmp/systemd/spectest-unit.service',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          'content' => content,
        },
      )
    end

    it do
      is_expected.to contain_service('spectest-unit_service').with(
        {
          'ensure'    => 'running',
          'name'      => 'spectest-unit',
          'enable'    => true,
          'provider'  => 'systemd',
        },
      )
    end
  end

  describe 'variable type and content validations' do
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
