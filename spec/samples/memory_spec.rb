describe Jimmy::Samplers::Memory do

  it 'returns the rss information about the process' do
    data = subject.collect
    expect(data.has_key?(:rss)).to be true
  end
end
