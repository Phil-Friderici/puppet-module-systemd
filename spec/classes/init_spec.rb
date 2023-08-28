require 'spec_helper'

describe 'systemd', type: :class do
  # for OS independent tests we use a supported RedHat version
  redhat = {
    supported_os: [
      {
        'operatingsystem'        => 'RedHat',
        'operatingsystemrelease' => ['7'],
      },
    ],
  }

  on_supported_os.sort.each do |os, facts|
    describe "on #{os} with defaults" do
      let(:facts) { facts }

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
  end

  on_supported_os(redhat).sort.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with units set to valid hash' do
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

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('systemd') }
        it { is_expected.to have_systemd__unit_resource_count(1) }
        it { is_expected.to contain_systemd__unit('example_unit') }

        it { is_expected.to contain_file('example_unit_file') }       # only here to reach 100% resource coverage
        it { is_expected.to contain_service('example_unit_service') } # only here to reach 100% resource coverage
      end
    end
  end

  on_supported_os(redhat).sort.each do |_os, os_facts|
    context 'variable type and content validations' do
      let(:facts) { os_facts }

      validations = {
        'Hash' => {
          name:    ['units'],
          valid:   [], # valid hashes are to complex to block test them here.
          invalid: ['string', ['array'], 3, 2.42, false],
          message: 'expects a Hash',
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
