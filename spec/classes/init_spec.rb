require 'spec_helper'
describe 'systemd' do
  # ensure that the class is passive by default
  describe 'when all parameters are unset (unsing module defaults)' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('systemd') }
    it { is_expected.to have_resource_count(1) }
    it { is_expected.to have_systemd__unit_resource_count(0) }

    it do
      is_expected.to contain_exec('systemd_reload').with(
        {
          'command'     => 'systemctl daemon-reload',
          'refreshonly' => true,
          'path'        => '/bin:/usr/bin:/usr/local/bin',
        },
      )
    end
  end

  describe 'when using parameter units' do
    let(:params) do
      {
        units: {
          'example_unit' => {
            'unit_description'  => 'Example unit',
            'service_execstart' => '/bin/echo',
            'install_wantedby'  => 'multi-user.target',
          }
        }
      }
    end

    content = <<-END.gsub(%r{^\s+\|}, '')
      |[Unit]
      |Description=Example unit
      |
      |[Service]
      |Type=simple
      |ExecStart=/bin/echo
      |
      |[Install]
      |WantedBy=multi-user.target
    END

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('systemd') }
    it { is_expected.to have_systemd__unit_resource_count(1) }
    it do
      is_expected.to contain_file('example_unit_file').with(
        {
          'ensure'  => 'present',
          'path'    => '/etc/systemd/system/example_unit.service',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          'content' => content,
        },
      )
    end

    it do
      is_expected.to contain_service('example_unit_service').with(
        {
          'ensure'    => 'running',
          'name'      => 'example_unit',
          'enable'    => true,
          'provider'  => 'systemd'
        },
      )
    end
  end
end
