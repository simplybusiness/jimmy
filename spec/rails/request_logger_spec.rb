describe Jimmy::Rails::RequestLogger do
  let(:app) { double(:app) }

  describe '#stream' do
    let(:tmp_directory) { Pathname.new(Dir.tmpdir) }
    let(:env) { 'xxxx' }
    let(:rails) { double(:rails, root: tmp_directory, env: env) }

    before do
      stub_const('Rails', rails)
      log_dir = tmp_directory + 'log'
      Dir.mkdir(tmp_directory + 'log') unless File.exist?(log_dir)
    end

    subject { described_class.new(app).stream }

    it 'returns the correct stream' do
      expect(subject.class).to eq(File)
      expected_log_dir = tmp_directory + 'log' + (Rails.env + '_json.log')
      expect(subject.path).to eq(expected_log_dir.to_s)
    end
  end
end
