require 'spec_helper'

describe Jimmy::Ruby::Logger do
  subject { Jimmy::Ruby::Logger.instance }

  before(:all) do
    Jimmy.configuration.logger_stream = StringIO.new
  end

  describe "log data" do
    before do
      Jimmy.configuration.logger_stream.truncate(0)
      Jimmy.configuration.logger_stream.rewind
    end

    let(:json){ JSON.parse(Jimmy.configuration.logger_stream.string.lines.last) }
    let(:log_data){ {test: "1", test2: "2"} }

    it 'starts with current time' do
      @start_time = Time.at(Time.now.to_i).utc # whole number of seconds
      subject.log(log_data)
      key, value = json.first
      expect(key).to eq 'timestamp'
      expect(Time.parse(value)).to be_between(@start_time, Time.now.utc)
    end

    it 'contains the logged data' do
      subject.log(log_data)
      expected_result = log_data.stringify_keys

      expect(json).to include expected_result
    end

    context "error" do
      context "with backtrace" do
        it 'logs the error' do
          begin
            raise ArgumentError, 'Something went wrong!'
          rescue => exception
          end
          subject.log(log_data, exception)
          expect(json['error_class']).to eq 'ArgumentError'
          expect(json['error_message']).to eq 'Something went wrong!'
          expect(json['error_backtrace']).to eq exception.backtrace.join("\n")
        end
      end

      context "without backtrace" do
        let(:exception) { StandardError.new('Something went wrong!') }

        it 'logs the error' do
          subject.log(log_data, exception)
          expect(json['error_class']).to eq 'StandardError'
          expect(json['error_message']).to eq 'Something went wrong!'
          expect(json['error_backtrace']).to eq ''
        end
      end
    end
  end
end
