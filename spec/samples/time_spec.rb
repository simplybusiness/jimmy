describe Jimmy::Samplers::Time do
  let(:now) { Time.now.utc }
  let(:duration) { 10 }
  let(:future_date) { now + duration }

  before do
    Timecop.freeze(now)
    @sampler = described_class.new
  end

  after do
    Timecop.return
  end

  subject { @sampler.collect }

  it 'returns the duration time' do
    Timecop.freeze(future_date)
    expect(subject[:duration]).to eq(duration)
  end

  it 'returns the timestamp' do
    expect(subject[:timestamp]).to eq(now.iso8601(3))
  end
end
