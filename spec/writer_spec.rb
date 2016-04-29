require 'spec_helper'

describe Jimmy::Writer do
  describe '#write' do
    let(:stream) { StringIO.new }

    subject{ described_class.new(stream) }

    before { subject.write(entry) }

    context 'with a valid entry' do
      let(:entry) { {key: 'value'} }

      it 'converts the entry to string' do
        converted_hash = "#{entry.to_json}\n"
        expect(stream.string).to eq(converted_hash)
      end

      context 'with multiple lines' do
        let(:second_entry) { {key: 'new_value'} }

        before { subject.write(second_entry) }

        it 'writes a new line for each entry' do
          expect(stream.string.lines.count).to eq(2)
        end
      end
    end

    context 'with an entry with invalid encoding' do
      let(:entry) { {key: "\xFF\xFEalert"} }
      let(:expected_entry) { {key: "alert"} }

      it 'forces the encoding to utf-8' do
        converted_hash = "#{expected_entry.to_json}\n"
        expect(stream.string).to eq(converted_hash)
      end
    end

  end
end
