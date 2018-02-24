# frozen_string_literal: true

require 'travis/packer_build/git_root'

describe Travis::PackerBuild::GitRoot do
  subject do
    described_class.new(
      commit_range: %w[fafafaf afafafa],
      branch: 'rad',
      dir: 'hej',
      remote: 'ray@interstellar.space:watermelon.git'
    )
  end

  it 'has a commit range' do
    expect(subject.commit_range).to eq(%w[fafafaf afafafa])
  end

  it 'has a branch' do
    expect(subject.branch).to eq('rad')
  end

  it 'has a dir' do
    expect(subject.dir).to eq('hej')
  end

  it 'has a remote' do
    expect(subject.remote).to eq('ray@interstellar.space:watermelon.git')
  end
end
