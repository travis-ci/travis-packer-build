require 'travis/packer_build/git_remote_path_parser'

describe Travis::PackerBuild::GitRemotePathParser do
  subject do
    described_class.new(
      clone_tmp: 'some/where/huh',
      git_logger: fake_log
    )
  end

  let(:fake_log) { instance_double('Logger', :fake_log) }

  let :fake_git do
    instance_double('Git::Bare', :fake_git)
  end

  before :each do
    allow(subject).to receive(:load_bare).and_return(fake_git)
    allow(subject).to receive(:clone_bare).and_return(fake_git)
  end

  it 'parses a singular path with no prefix' do
    parsed = subject.parse('lol@wut.example.org:foo.git::')
    expect(parsed.length).to eq(1)
    parsed0 = parsed.first
    expect(parsed0.path).to eq('')
  end
end
