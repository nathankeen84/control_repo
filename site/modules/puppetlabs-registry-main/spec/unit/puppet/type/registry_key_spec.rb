# frozen_string_literal: true

require 'spec_helper'
require 'puppet/resource'
require 'puppet/resource/catalog'
require 'puppet/type/registry_key'

describe Puppet::Type.type(:registry_key) do
  let(:catalog) { Puppet::Resource::Catalog.new }

  # This is overridden here so we get a consistent association with the key
  # and a catalog using memoized let methods.
  let(:key) { Puppet::Type.type(:registry_key).new(name: 'HKLM\Software', catalog: catalog) }
  let(:provider) { Puppet::Provider.new(key) }

  before(:each) do
    key.provider = provider
  end

  [:ensure].each do |property|
    it "has a #{property} property" do
      expect(described_class.attrclass(property).ancestors).to be_include(Puppet::Property)
    end

    it "has documentation for its #{property} property" do
      expect(described_class.attrclass(property).doc).to be_instance_of(String)
    end
  end

  describe 'path parameter' do
    it 'has a path parameter' do
      expect(Puppet::Type.type(:registry_key).attrtype(:path).must == :param)
    end

    # rubocop:disable RSpec/RepeatedExample,RSpec/RepeatedDescription
    ['hklm', 'hklm\\software', 'hklm\\software\\vendor'].each do |path|
      it "accepts #{path}" do
        expect(key[:path] = path)
      end
    end

    ['hku', 'hku\\.DEFAULT', 'hku\\.DEFAULT\\software', 'hku\\.DEFAULT\\software\\vendor'].each do |path|
      it "accepts #{path}" do
        expect(key[:path] = path)
      end
    end
    # rubocop:enable RSpec/RepeatedExample,RSpec/RepeatedDescription

    ['HKEY_DYN_DATA', 'HKEY_PERFORMANCE_DATA'].each do |path|
      it "rejects #{path} as unsupported case insensitively" do
        expect { key[:path] = path }.to raise_error(Puppet::Error, %r{Unsupported})
      end
    end

    ['hklm\\', 'hklm\\foo\\', 'unknown', 'unknown\\subkey', '\\:hkey'].each do |path|
      it "rejects #{path} as invalid" do
        path = "hklm\\#{'a' * 256}"
        expect { key[:path] = path }.to raise_error(Puppet::Error, %r{Invalid registry key})
      end
    end

    ['HKLM', 'HKEY_LOCAL_MACHINE', 'hklm'].each do |root|
      it "canonicalizes the root key #{root}" do
        expect(key[:path] = root)
        expect(key[:path].must == 'hklm')
      end
    end

    it 'should be case-preserving'
    it 'should be case-insensitive'
    it 'should autorequire ancestor keys'
    it 'supports 32-bit keys' do
      expect(key[:path] = '32:hklm\software')
    end
  end

  describe '#eval_generate' do
    context 'without purging' do
      it 'returns an empty array' do
        expect(key.eval_generate.must(be_empty))
      end
    end

    context 'when purging' do
      let(:catalog) { Puppet::Resource::Catalog.new }

      # This is overridden here so we get a consistent association with the key
      # and a catalog using memoized let methods.
      let(:key) { Puppet::Type.type(:registry_key).new(name: 'HKLM\Software', catalog: catalog) }

      before :each do
        key[:purge_values] = true
        catalog.add_resource(key)
        catalog.add_resource(Puppet::Type.type(:registry_value).new(path: "#{key[:path]}\\val1", catalog: catalog))
        catalog.add_resource(Puppet::Type.type(:registry_value).new(path: "#{key[:path]}\\vAl2", catalog: catalog))
        catalog.add_resource(Puppet::Type.type(:registry_value).new(path: "#{key[:path]}\\\\val\\3", catalog: catalog))
      end

      it "returns an empty array if the key doesn't have any values" do
        expect(key.provider).to receive(:values).and_return([])
        key.eval_generate.must be_empty
      end

      # rubocop:disable Lint/Void
      it 'purges existing values that are not being managed (without backslash)' do
        expect(key.provider).to receive(:values).and_return(['val1', 'val\3', 'val99'])
        resources = key.eval_generate
        resources.count.must == 1
        res = resources.first

        res[:ensure].must == :absent
        res[:path].must == "#{key[:path]}\\val99"
      end

      it 'purges existing values that are not being managed (with backslash)' do
        expect(key.provider).to receive(:values).and_return(['val1', 'val\3', 'val\99'])

        resources = key.eval_generate
        resources.count.must == 1
        res = resources.first

        res[:ensure].must == :absent
        res[:path].must == "#{key[:path]}\\\\val\\99"
      end

      it 'purges existing values that are not being managed and case insensitive)' do
        expect(key.provider).to receive(:values).and_return(['VAL1', 'VaL\3', 'Val99'])
        resources = key.eval_generate
        resources.count.must == 1
        res = resources.first

        res[:ensure].must == :absent
        res[:path].must == "#{key[:path]}\\Val99"
      end
      # rubocop:enable Lint/Void

      it 'returns an empty array if all existing values are being managed' do
        expect(key.provider).to receive(:values).and_return(['val1', 'val2', 'val\3'])
        key.eval_generate.must be_empty
      end
    end
  end

  describe 'resource aliases' do
    let :the_catalog do
      Puppet::Resource::Catalog.new
    end

    let(:the_resource_name) { 'HKLM\Software\Vendor\PuppetLabs' }

    let :the_resource do
      # JJM Holy cow this is an intertangled mess.  ;)
      resource = Puppet::Type.type(:registry_key).new(name: the_resource_name, catalog: the_catalog)
      the_catalog.add_resource resource
      resource
    end

    it 'initializes the catalog instance variable' do
      expect(the_resource.catalog.must(be the_catalog))
    end

    it 'allows case insensitive lookup using the downcase path' do
      expect(the_resource.must(be the_catalog.resource(:registry_key, the_resource_name.downcase)))
    end

    it 'preserves the case of the user specified path' do
      expect(the_resource.must(be the_catalog.resource(:registry_key, the_resource_name)))
    end

    it 'returns the same resource regardless of the alias used' do
      expect(the_resource.must(be the_catalog.resource(:registry_key, the_resource_name)))
      expect(the_resource.must(be the_catalog.resource(:registry_key, the_resource_name.downcase)))
    end
  end
end
