require 'spec_helper_acceptance'

hostname = default.node_name
describe 'managing java chain keys', :unless => UNSUPPORTED_PLATFORMS.include?(fact('operatingsystem')) do
  include_context 'common variables'

  case fact('osfamily')
    when "windows"
      target = 'c:/chain_key.ks'
    else
      target = '/etc/chain_key.ks'
  end
  it 'creates a private key with chain certs' do
    pp = <<-EOS
      java_ks { 'broker.example.com:#{target}':
        ensure       => latest,
        certificate  => "#{@temp_dir}ca.pem",
        chain        => "#{@temp_dir}chain.pem",
        private_key  => "#{@temp_dir}privkey.pem",
        password     => 'puppet',
        path         => #{@resource_path},
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
  end

  it 'verifies the private key' do
    shell("#{@keytool_path}keytool -list -v -keystore #{target} -storepass puppet") do |r|
      expect(r.exit_code).to be_zero
      expect(r.stdout).to match(/Alias name: broker\.example\.com/)
      expect(r.stdout).to match(/Entry type: (keyEntry|PrivateKeyEntry)/)
      expect(r.stdout).to match(/CN=Test CA/)
    end
  end
end
