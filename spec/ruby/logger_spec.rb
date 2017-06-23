require 'spec_helper'

describe Jimmy::Ruby::Logger do
  subject { Jimmy::Ruby::Logger.instance }

  before(:all) do
    Jimmy.configuration.logger_stream = StringIO.new
  end

  describe "log data" do
    let(:json){ JSON.parse(Jimmy.configuration.logger_stream.string.lines.first) }
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
  end
end
