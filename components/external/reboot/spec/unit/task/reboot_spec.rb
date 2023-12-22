# frozen_string_literal: true

require 'spec_helper'
# require_relative '../../../tasks/init'
require "#{File.dirname(__FILE__)}/../../../tasks/init.rb"

describe Task::Reboot do
  context 'on Windows' do
    before(:each) do
      allow(Facter).to receive(:value).with(:kernel).and_return('windows')
    end

    context 'when rebooting' do
      let(:reboot) { described_class.new }

      it 'runs the correct command' do
        command = 'shutdown.exe /r /t 3 /d p:4:1 '
        expect(reboot).to receive(:shutdown_executable_windows).and_return('shutdown.exe')
        expect(reboot).to receive(:async_command).with(command).and_return(nil)
        reboot.execute!
      end

      context 'with a timeout' do
        let(:reboot) { described_class.new('timeout' => 20) }

        it 'handles the timeout' do
          command = 'shutdown.exe /r /t 20 /d p:4:1 '
          expect(reboot).to receive(:shutdown_executable_windows).and_return('shutdown.exe')
          expect(reboot).to receive(:async_command).with(command).and_return(nil)
          reboot.execute!
        end

        it 'does not allow timeouts < 3' do
          reboot = described_class.new('timeout' => 0)
          command = 'shutdown.exe /r /t 3 /d p:4:1 '
          expect(reboot).to receive(:shutdown_executable_windows).and_return('shutdown.exe')
          expect(reboot).to receive(:async_command).with(command).and_return(nil)
          reboot.execute!
        end
      end
    end

    context 'when shutting down' do
      let(:reboot) { described_class.new('shutdown_only' => true) }

      it 'runs the correct command' do
        command = 'shutdown.exe /s /t 3 /d p:4:1 '
        expect(reboot).to receive(:shutdown_executable_windows).and_return('shutdown.exe')
        expect(reboot).to receive(:async_command).with(command).and_return(nil)
        reboot.execute!
      end
    end
  end

  context 'on Solaris' do
    before(:each) { allow(Facter).to receive(:value).with(:kernel).and_return('SunOS') }

    context 'when rebooting' do
      let(:reboot) { described_class.new }

      it 'runs the correct command' do
        # Enforces minimum 3s timeout.
        command = ['shutdown', '-y', '-i', '6', '-g', 3, "''", '</dev/null', '>/dev/null', '2>&1', '&']
        expect(reboot).to receive(:async_command).with(command).and_return(nil)
        reboot.execute!
      end

      context 'with a timeout' do
        let(:reboot) { described_class.new('timeout' => 20) }

        it 'handles the timeout' do
          command = ['shutdown', '-y', '-i', '6', '-g', 20, "''", '</dev/null', '>/dev/null', '2>&1', '&']
          expect(reboot).to receive(:async_command).with(command).and_return(nil)
          reboot.execute!
        end
      end
    end

    context 'when shutting down' do
      let(:reboot) { described_class.new('shutdown_only' => true) }

      it 'runs the correct command' do
        # Enforces minimum 3s timeout.
        command = ['shutdown', '-y', '-i', '5', '-g', 3, "''", '</dev/null', '>/dev/null', '2>&1', '&']
        expect(reboot).to receive(:async_command).with(command).and_return(nil)
        reboot.execute!
      end
    end
  end

  context 'on Linux' do
    before(:each) { allow(Facter).to receive(:value).with(:kernel).and_return('Linux') }

    context 'when rebooting' do
      let(:reboot) { described_class.new }

      it 'runs the correct command' do
        command = ['shutdown', '-r', 'now', "''", '</dev/null', '>/dev/null', '2>&1', '&']
        # Enforces minimum 3s timeout.
        expect(reboot).to receive(:async_command).with(command, 3).and_return(nil)
        reboot.execute!
      end

      context 'with a small timeout' do
        let(:reboot) { described_class.new('timeout' => 20) }

        it 'handles the timeout by sleeping' do
          command = ['shutdown', '-r', 'now', "''", '</dev/null', '>/dev/null', '2>&1', '&']
          expect(reboot).to receive(:async_command).with(command, 20).and_return(nil)
          reboot.execute!
        end
      end

      context 'with a large timeout' do
        let(:reboot) { described_class.new('timeout' => 90) }

        it 'handles the timeout by sleeping' do
          command = ['shutdown', '-r', '+1', "''", '</dev/null', '>/dev/null', '2>&1', '&']
          expect(reboot).to receive(:async_command).with(command, 30).and_return(nil)
          reboot.execute!
        end
      end
    end

    context 'when shutting down' do
      let(:reboot) { described_class.new('shutdown_only' => true) }

      it 'runs the correct command' do
        # Enforces minimum 3s timeout.
        command = ['shutdown', '-P', 'now', "''", '</dev/null', '>/dev/null', '2>&1', '&']
        expect(reboot).to receive(:async_command).with(command, 3).and_return(nil)
        reboot.execute!
      end
    end
  end
end
