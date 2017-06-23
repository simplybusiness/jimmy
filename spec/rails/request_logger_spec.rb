require 'spec_helper'

require 'socket'

describe Jimmy::Rails::RequestLogger do
  let(:app) { double(:app) }

  let(:env) { 'xxxx' }
  let(:tmp_directory) { Pathname.new(Dir.tmpdir) }
  let(:rails) { double(:rails, root: tmp_directory, env: env) }

  before do
    stub_const('Rails', rails)
    Jimmy.remove_instance_variable(:@configuration) if Jimmy.instance_variable_defined?(:@configuration)
  end

  describe '#stream' do

    before do
      log_dir = tmp_directory + 'log'
      Dir.mkdir(tmp_directory + 'log') unless File.exist?(log_dir)
    end

    subject { described_class.new(app).stream }

    context "without file_path configuration" do
      it 'returns the default stream' do
        expect(subject.class).to eq(File)
        expected_log_dir = ::Rails.root + 'log' + (::Rails.env + '_json.log')
        expect(subject.path).to eq(expected_log_dir.to_s)
      end
    end

    context "with file_path configuration" do
      before do
        Jimmy.configure do |config|
          config.file_path = ::Rails.root + 'log' + 'testing_json.log'
        end
      end

      it 'returns the correct stream' do
        expect(subject.class).to eq(File)
        expected_log_dir = ::Rails.root + 'log' + 'testing_json.log'
        expect(subject.path).to eq(expected_log_dir.to_s)
      end
    end
  end

  context 'no network is available (so can still test)' do
    subject { described_class.new(app).local_address }

    it 'on test environment' do
      allow(Rails.env).to receive(:test?).and_return(true)
      allow(UDPSocket).to receive(:open).and_raise(Errno::ENETUNREACH)
      expect{ subject }.to_not raise_error
    end

    it 'on other environments' do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(UDPSocket).to receive(:open).and_raise(Errno::ENETUNREACH)

      expect{ subject }.to raise_error(Errno::ENETUNREACH)
    end
  end
end
