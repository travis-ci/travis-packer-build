require 'travis/packer_build'

describe Travis::PackerBuild::GitPath do
  subject do
    described_class.new(fake_git_repo, 'some/enchanted/place', 'fafafaf')
  end

  let :fake_git_repo do
    instance_double(
      'Git::Base', :git,
      remotes: [
        instance_double(
          'Git::Remote', :remote_origin,
          name: 'origin',
          url: 'lol@wut.git'
        ),
        instance_double(
          'Git::Remote', :remote_bork,
          name: 'bork',
          url: 'no/no/no/no/no.git'
        )
      ]
    )
  end

  before :each do
    allow(fake_git_repo).to receive(:show)
      .with('fafafaf', 'some/enchanted/place')
      .and_return("flowers\nunicorns\nn'at\n")
  end

  it 'has a path' do
    expect(subject.path).to eq('some/enchanted/place')
  end

  it 'has a repo' do
    expect(subject.repo).to eq(fake_git_repo)
  end

  it 'has a default ref' do
    expect(subject.default_ref).to eq('fafafaf')
  end

  it 'has a namespaced path' do
    expect(subject.namespaced_path).to eq('lol@wut.git::some/enchanted/place')
  end

  it 'has an origin url' do
    expect(subject.origin_url).to eq('lol@wut.git')
  end

  it 'can show itself' do
    expect(subject.show).to eq("flowers\nunicorns\nn'at\n")
  end
end
