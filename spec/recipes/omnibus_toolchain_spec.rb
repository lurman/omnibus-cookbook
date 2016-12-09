require 'spec_helper'

describe 'omnibus::_omnibus_toolchain' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  context 'on platforms that use omnibus toolchain' do
    it 'installs omnibus-toolchain' do
      expect(chef_run).to upgrade_chef_ingredient('omnibus-toolchain')
    end

    context 'when version has an override' do
      before do
        chef_run.node.normal['omnibus']['toolchain_version'] = '1.1.0-30499'
        chef_run.converge(described_recipe)
      end

      it 'installs a specific version of omnibus-toolchain' do
        expect(chef_run).to upgrade_chef_ingredient('omnibus-toolchain').with version: '1.1.0-30499'
      end
    end

    context 'when channel has an override' do
      before do
        chef_run.node.normal['omnibus']['toolchain_channel'] = 'unstable'
        chef_run.converge(described_recipe)
      end

      it 'installs omnibus-toolchain from a specific channel' do
        expect(chef_run).to upgrade_chef_ingredient('omnibus-toolchain').with channel: :unstable
      end
    end
  end

  context 'on Windows' do
    let(:node_name) { 'chefdk-windows-2008r2-builder-1a6dad' }
    let(:platform_version) { '2008R2' }

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'windows', version: platform_version) do |node|
        node.name(node_name)
        node.automatic['fqdn'] = node_name
      end.converge(described_recipe)
    end

    let(:omnibus_env_path) { chef_run.node.run_state[:omnibus_env]['PATH'] }
    let(:omnibus_msystem) { chef_run.node.run_state[:omnibus_env]['MSYSTEM'] }

    it 'exports the embedded CA certificate bundle' do
      expect(chef_run.node.run_state[:omnibus_env]['SSL_CERT_FILE']).to(
        eq(['C:\opscode\omnibus-toolchain\embedded\ssl\certs\cacert.pem'])
      )
    end

    it 'exports the omnibus-toolchain install location' do
      expect(chef_run.node.run_state[:omnibus_env]['OMNIBUS_TOOLCHAIN_INSTALL_DIR']).to(
        eq(['C:\opscode\omnibus-toolchain'])
      )
    end

    it 'prefers the 64-bit MinGW toolchain' do
      expect(omnibus_msystem).to eq(['MINGW64'])
    end

    context 'when a Windows node has a 32-bit architecture' do
      # This version of Windows has a 32-bit arch in Fauxhai:
      #
      #   https://github.com/customink/fauxhai/blob/master/lib/fauxhai/platforms/windows/2003R2.json#L186
      #
      let(:platform_version) { '2003R2' }

      it 'prefers the 32-bit MinGW toolchain' do
        expect(omnibus_msystem).to eq(['MINGW32'])
      end
    end

    context 'when a Windows node has i386 in its name' do
      let(:node_name) { 'chefdk-windows-2008r2-i386-builder-dcb6f4' }

      it 'prefers the 32-bit MinGW toolchain' do
        expect(omnibus_msystem).to eq(['MINGW32'])
      end
    end
  end
end
