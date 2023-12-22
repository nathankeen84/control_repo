# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'puppet/util/ini_file'

describe Puppet::Util::IniFile do
  subject(:ini_sub) { described_class.new('/my/ini/file/path') }

  before :each do
    allow(File).to receive(:file?).with('/my/ini/file/path').and_return(true)
    allow(described_class).to receive(:readlines).once.with('/my/ini/file/path') do
      sample_content
    end
  end

  context 'when parsing a file' do
    let(:sample_content) do
      template = <<-INIFILE
        # This is a comment
        [section1]
        ; This is also a comment
        foo=foovalue

        bar = barvalue
        baz =
        [section2]

        foo= foovalue2
        baz=bazvalue
         ; commented = out setting
            #another comment
         ; yet another comment
         zot = multi word value
         xyzzy['thing1']['thing2']=xyzzyvalue
         l=git log
      INIFILE
      template.split("\n")
    end

    it 'parses the correct number of sections' do
      # there is always a "global" section, so our count should be 3.
      expect(ini_sub.section_names.length).to eq(3)
    end

    it 'parses the correct section_names' do
      # there should always be a "global" section named "" at the beginning of the list
      expect(ini_sub.section_names).to eq(['', 'section1', 'section2'])
    end

    it 'exposes settings for sections #section1' do
      expect(ini_sub.get_settings('section1')).to eq('bar' => 'barvalue',
                                                     'baz' => '',
                                                     'foo' => 'foovalue')
    end

    it 'exposes settings for sections #section2' do
      expect(ini_sub.get_settings('section2')).to eq('baz' => 'bazvalue',
                                                     'foo' => 'foovalue2',
                                                     'l' => 'git log',
                                                     "xyzzy['thing1']['thing2']" => 'xyzzyvalue',
                                                     'zot' => 'multi word value')
    end
  end

  context 'when parsing a file whose first line is a section' do
    let(:sample_content) do
      template = <<-INIFILE
        [section1]
        ; This is a comment
        foo=foovalue
      INIFILE
      template.split("\n")
    end

    it 'parses the correct number of sections' do
      # there is always a "global" section, so our count should be 2.
      expect(ini_sub.section_names.length).to eq(2)
    end

    it 'parses the correct section_names' do
      # there should always be a "global" section named "" at the beginning of the list
      expect(ini_sub.section_names).to eq(['', 'section1'])
    end

    it 'exposes settings for sections' do
      expect(ini_sub.get_value('section1', 'foo')).to eq('foovalue')
    end
  end

  context "when parsing a file with a 'global' section" do
    let(:sample_content) do
      template = <<-INIFILE
        foo = bar
        [section1]
        ; This is a comment
        foo=foovalue
      INIFILE
      template.split("\n")
    end

    it 'parses the correct number of sections' do
      # there is always a "global" section, so our count should be 2.
      expect(ini_sub.section_names.length).to eq(2)
    end

    it 'parses the correct section_names' do
      # there should always be a "global" section named "" at the beginning of the list
      expect(ini_sub.section_names).to eq(['', 'section1'])
    end

    it 'exposes settings for sections #bar' do
      expect(ini_sub.get_value('', 'foo')).to eq('bar')
    end

    it 'exposes settings for sections #foovalue' do
      expect(ini_sub.get_value('section1', 'foo')).to eq('foovalue')
    end
  end

  context 'when updating a file with existing empty values' do
    let(:sample_content) do
      template = <<-INIFILE
        [section1]
        foo=
        #bar=
        #xyzzy['thing1']['thing2']='xyzzyvalue'
      INIFILE
      template.split("\n")
    end

    before :each do
      expect(ini_sub.get_value('section1', 'far')).to be_nil
      expect(ini_sub.get_value('section1', 'bar')).to be_nil
      expect(ini_sub.get_value('section1', "xyzzy['thing1']['thing2']")).to be_nil
    end
    # rubocop:enable RSpec/ExpectInHook

    it 'properlies update uncommented values' do
      ini_sub.set_value('section1', 'foo', ' = ', 'foovalue')
      expect(ini_sub.get_value('section1', 'foo')).to eq('foovalue')
    end

    it 'properlies update uncommented values without separator' do
      ini_sub.set_value('section1', 'foo', 'foovalue')
      expect(ini_sub.get_value('section1', 'foo')).to eq('foovalue')
    end

    it 'properlies update commented value' do
      ini_sub.set_value('section1', 'bar', ' = ', 'barvalue')
      expect(ini_sub.get_value('section1', 'bar')).to eq('barvalue')
    end

    it 'properlies update commented values' do
      ini_sub.set_value('section1', "xyzzy['thing1']['thing2']", ' = ', 'xyzzyvalue')
      expect(ini_sub.get_value('section1', "xyzzy['thing1']['thing2']")).to eq('xyzzyvalue')
    end

    it 'properlies update commented value without separator' do
      ini_sub.set_value('section1', 'bar', 'barvalue')
      expect(ini_sub.get_value('section1', 'bar')).to eq('barvalue')
    end

    it 'properlies update commented values without separator' do
      ini_sub.set_value('section1', "xyzzy['thing1']['thing2']", 'xyzzyvalue')
      expect(ini_sub.get_value('section1', "xyzzy['thing1']['thing2']")).to eq('xyzzyvalue')
    end

    it 'properlies add new empty values' do
      ini_sub.set_value('section1', 'baz', ' = ', 'bazvalue')
      expect(ini_sub.get_value('section1', 'baz')).to eq('bazvalue')
    end

    it 'adds new empty values without separator' do
      ini_sub.set_value('section1', 'baz', 'bazvalue')
      expect(ini_sub.get_value('section1', 'baz')).to eq('bazvalue')
    end
  end

  context 'when the file has quotation marks in its section names' do
    let(:sample_content) do
      template = <<-INIFILE
        [branch "main"]
                remote = origin
                merge = refs/heads/main

        [alias]
        to-deploy = log --merges --grep='pull request' --format='%s (%cN)' origin/production..origin/main
        [branch "production"]
                remote = origin
                merge = refs/heads/production
      INIFILE
      template.split("\n")
    end

    it 'parses the sections' do
      expect(ini_sub.section_names).to contain_exactly('', 'branch "main"', 'alias', 'branch "production"')
    end
  end

  context 'when Samba INI file with dollars in section names' do
    let(:sample_content) do
      template = <<-INIFILE
        [global]
          workgroup = FELLOWSHIP
          ; ...
          idmap config * : backend = tdb

        [printers]
          comment = All Printers
          ; ...
          browseable = No

        [print$]
          comment = Printer Drivers
          path = /var/lib/samba/printers

        [Shares]
          path = /home/shares
          read only = No
          guest ok = Yes
      INIFILE
      template.split("\n")
    end

    it 'parses the correct section_names' do
      expect(ini_sub.section_names).to contain_exactly('', 'global', 'printers', 'print$', 'Shares')
    end
  end

  context 'when section names with forward slashes in them' do
    let(:sample_content) do
      template = <<-INIFILE
        [monitor:///var/log/*.log]
        disabled = test_value
      INIFILE
      template.split("\n")
    end

    it 'parses the correct section_names' do
      expect(ini_sub.section_names).to contain_exactly('', 'monitor:///var/log/*.log')
    end
  end

  context 'when KDE Configuration with braces in setting names' do
    let(:sample_content) do
      template = <<-INIFILE
              [khotkeys]
        _k_friendly_name=khotkeys
        {5465e8c7-d608-4493-a48f-b99d99fdb508}=Print,none,PrintScreen
        {d03619b6-9b3c-48cc-9d9c-a2aadb485550}=Search,none,Search
      INIFILE
      template.split("\n")
    end

    it 'exposes settings for sections #print' do
      expect(ini_sub.get_value('khotkeys', '{5465e8c7-d608-4493-a48f-b99d99fdb508}')).to eq('Print,none,PrintScreen')
    end

    it 'exposes settings for sections #search' do
      expect(ini_sub.get_value('khotkeys', '{d03619b6-9b3c-48cc-9d9c-a2aadb485550}')).to eq('Search,none,Search')
    end
  end

  context 'when Configuration with colons in setting names' do
    let(:sample_content) do
      template = <<-INIFILE
              [Drive names]
        A:=5.25" Floppy
        B:=3.5" Floppy
        C:=Winchester
      INIFILE
      template.split("\n")
    end

    it 'exposes settings for sections #A' do
      expect(ini_sub.get_value('Drive names', 'A:')).to eq '5.25" Floppy'
    end

    it 'exposes settings for sections #B' do
      expect(ini_sub.get_value('Drive names', 'B:')).to eq '3.5" Floppy'
    end

    it 'exposes settings for sections #C' do
      expect(ini_sub.get_value('Drive names', 'C:')).to eq 'Winchester'
    end
  end

  context 'when Configuration with spaces in setting names' do
    let(:sample_content) do
      template = <<-INIFILE
        [global]
          # log files split per-machine:
          log file = /var/log/samba/log.%m

          kerberos method = system keytab
          passdb backend = tdbsam
          security = ads
      INIFILE
      template.split("\n")
    end

    it 'exposes settings for sections #log' do
      expect(ini_sub.get_value('global', 'log file')).to eq '/var/log/samba/log.%m'
    end

    it 'exposes settings for sections #kerberos' do
      expect(ini_sub.get_value('global', 'kerberos method')).to eq 'system keytab'
    end

    it 'exposes settings for sections #passdb' do
      expect(ini_sub.get_value('global', 'passdb backend')).to eq 'tdbsam'
    end

    it 'exposes settings for sections #security' do
      expect(ini_sub.get_value('global', 'security')).to eq 'ads'
    end
  end
end
