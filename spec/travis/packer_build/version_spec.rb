require 'travis/packer_build/version'

describe Travis::PackerBuild::VERSION do
  subject { Travis::PackerBuild::VERSION }

  it 'is non empty' do
    expect(subject).to_not be_empty
  end

  it 'is semver-ish' do
    expect do
      subject.split('.').map { |s| Integer(s) }
    end.to_not raise_error
  end
end
