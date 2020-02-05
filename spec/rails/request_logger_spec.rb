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
    let(:attributes) {
      {
        uri: "/example?personally_identifiable_info=private_email@example.com",
        query_params: { personally_identifiable_info: "private_email@example.com" }
      }
    }

    context "without filter_uri configuration" do
      before do
        filter_params = [:personally_identifiable_info]
        setup_rails_filter_params(filter_params)
      end

      it 'filters the attributes' do
        filtered_attributes = filter_attributes(attributes)

        expect(filtered_attributes[:query_params]).
          to eq({ personally_identifiable_info: "[FILTERED]" })
      end
    end

    context "with filter_uri configuration" do
      before do
        Jimmy.configure do |config|
          config.filter_uri = true
        end

        filter_params = [:personally_identifiable_info]
        setup_rails_filter_params(filter_params)
      end

      it 'filters the attributes' do
        filtered_attributes = filter_attributes(attributes)

        expect(filtered_attributes[:query_params]).
          to eq({ personally_identifiable_info: "[FILTERED]" })
      end

      it 'returns the given uri when there are no query parameters' do
        attributes = { uri: "/example" }

        expect(filtered_uri(attributes)).to eq "/example"
      end

      context 'with filter_parameters as symbols' do
        it 'filters the uri for entire matches of the word' do
          expect(filtered_uri(attributes)).to eq "/example?personally_identifiable_info=[FILTERED]"
        end

        it 'filters the uri for partial matches of the word' do
          attributes = { uri: "/example?personally_identifiable_information=zoop" }

          expect(filtered_uri(attributes)).to eq "/example?personally_identifiable_information=[FILTERED]"
        end
      end

      context 'with filter_parameters as contained regexps' do
        before do
          filter_params = [/^word$/, /^other_word$/]
          setup_rails_filter_params(filter_params)
        end

        it 'filters the uri for entire matches of the word' do
          attributes = { uri: "/example?word=solidity&other_word=liquidity" }

          expect(filtered_uri(attributes)).to eq "/example?word=[FILTERED]&other_word=[FILTERED]"
        end

        it 'does not filter the uri for partial matches of the word' do
          attributes = [
            { uri: "/example?whoahword=solidity&whoahother_word=liquidity" },
            { uri: "/example?wordyoo=solidity&other_wordyoo=liquidity" }
          ]

          attributes.each do |attrs|
            expect(filtered_uri(attrs)).to eq attrs[:uri]
          end
        end
      end

      context 'with filter_parameters as non-contained regexps' do
        before do
          filter_params = [/l.*g/]
          setup_rails_filter_params(filter_params)
        end

        it 'filters the uri for matches' do
          attributes = { uri: "/example?longoword=solidity" }
          expect(filtered_uri(attributes)).to eq "/example?longoword=[FILTERED]"
        end
      end
    end

    def setup_rails_filter_params(filter_params)
      allow(::Rails).to receive_message_chain(:application, :config, :filter_parameters)
        .and_return filter_params
    end

    def filtered_uri(attributes)
      filter_attributes(attributes)[:uri]
    end

    def filter_attributes(attributes)
      described_class.new(app).filter_attributes(attributes)
    end
  end
end
