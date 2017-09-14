require 'travis/packer_build/git_change_finder'

describe Travis::PackerBuild::GitChangeFinder do
  subject do
    described_class.new(
      root: fake_root,
      clone_tmp: 'some/nonexistent/huh',
      packer_templates_path: [fake_packer_templates_path],
      git_logger: fake_log
    )
  end

  let(:fake_git) do
    instance_double('Git::Base', :fake_git)
  end

  let(:fake_log) { instance_double('Logger', :fake_log) }

  let :fake_packer_templates_path do
    instance_double(
      'Travis::PackerBuild::GitPath',
      :fake_packer_templates_path
    )
  end

  let :fake_root do
    instance_double(
      'Travis::PackerBuild::GitRoot',
      :root,
      commit_range: %w[fafafaf afafafa]
    )
  end

  let :fake_diff do
    instance_double('Git::Diff', :fake_diff)
  end

  let :fake_name_status do
    {
      'hambro/castle/dog.txt' => 'M',
      'comfort/travel/soda.txt' => 'A',
      'clog/dowa/hello' => 'D'
    }
  end

  before do
    allow(subject).to receive(:root_repo_git).and_return(fake_git)
    allow(fake_git).to receive(:gtree).with('fafafaf').and_return(fake_git)
    allow(fake_git).to receive(:diff).with('afafafa').and_return(fake_diff)
    allow(fake_diff).to receive(:name_status).and_return(fake_name_status)
  end

  it 'finds changed paths via git' do
    found = subject.find
    expect(found).to_not be_empty
    expect(found.length).to eq(2)
  end
end
