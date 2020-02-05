require 'spec_helper'
require 'socket'
require 'action_dispatch'
require 'active_support/parameter_filter' if ActiveSupport::VERSION::MAJOR >= 6

describe Jimmy::Rails::RequestLogger do
  let(:app) { double(:app) }

  let(:env) { 'xxxx' }
  let(:tmp_directory) { Pathname.new(Dir.tmpdir) }
  let(:rails) { double(:rails, root: tmp_directory, env: env) }

  before do
    stub_const('Rails', rails)
    Jimmy.remove_instance_variable(:@configuration) if Jimmy.instance_variable_defined?(:@configuration)
    log_dir = tmp_directory + 'log'
    Dir.mkdir(tmp_directory + 'log') unless File.exist?(log_dir)
  end

  describe '#stream' do

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

  describe '#filter_attributes' do
    subject { described_class.new(app) }

    let(:klass) do
      if defined?(ActiveSupport::ParameterFilter)
        ActiveSupport::ParameterFilter
      else
        ActionDispatch::Http::ParameterFilter
      end
    end
    let(:filter_string) { [:personally_identifiable_info] }
    let(:attributes) {
      {
        uri: "/example?personally_identifiable_info=private_email@example.com",
        query_params: { personally_identifiable_info: "private_email@example.com" }
      }
    }

    before do
      allow(::Rails).to receive_message_chain(:application, :config, :filter_parameters)
        .and_return filter_string
    end

    context "without filter_uri configuration" do
      it 'instantiates a new ParameterFilter' do
        expect(klass).to receive(:new).with(filter_string).and_call_original
        subject.filter_attributes(attributes)
      end

      it 'passes the attributes to the parameter_filter filter method' do
        parameter_filter = double(:ParameterFilter)
        allow(klass).to receive(:new).and_return parameter_filter
        expect(parameter_filter).to receive(:filter).with(attributes)
        subject.filter_attributes(attributes)
      end
    end

    context "with filter_uri configuration" do
      before do
        Jimmy.configure do |config|
          config.filter_uri = true
        end
      end

      it 'filters the attributes as standard' do
        filtered_attributes = subject.filter_attributes(attributes)

        expect(filtered_attributes[:query_params]).
          to eq({ personally_identifiable_info: "[FILTERED]" })
      end

      context 'with filter_parameters as symbols' do
        it 'additionally filters the uri' do
          filtered_attribues = subject.filter_attributes(attributes)
          expect(filtered_attribues[:uri]).to eq "/example?personally_identifiable_info=[FILTERED]"
        end
      end

      context 'with filter_parameters as contained regexps' do
        let(:filter_string) { [/^word$/] }
        let(:attributes) { { uri: "/example?word=solidity" } }

        it 'additionally filters the uri' do
          filtered_attribues = subject.filter_attributes(attributes)
          expect(filtered_attribues[:uri]).to eq "/example?word=[FILTERED]"
        end
      end
    end
  end
end
