require 'travis/packer_build/request_builder'

describe Travis::PackerBuild::RequestBuilder do
  subject do
    described_class.new(
      travis_api_token: 'wherps',
      target_repo_slug: 'serious/application',
      builders: %w(blastoise bulbasaur),
      commit_range: %w(fafafaf afafafa),
      branch: 'meister'
    )
  end

  let(:requests) { subject.build(%w(larping cosplay)) }

  it 'is has a body' do
    requests.each do |_, request|
      expect(request.body).to_not be_empty
    end
  end

  it 'is json' do
    requests.each do |_, request|
      expect(request.headers['Content-Type']).to eq('application/json')
    end
  end

  it 'specifies API version 3' do
    requests.each do |_, request|
      expect(request.headers['Travis-API-Version']).to eq('3')
    end
  end

  it 'includes authorization' do
    requests.each do |_, request|
      expect(request.headers['Authorization']).to eq('token wherps')
    end
  end

  describe 'body' do
    let(:body) { subject.send(:body, 'flurb') }

    it 'has a message with commit' do
      expect(body[:message]).to match(/commit-range=fafafaf\.\.\.afafafa/)
    end

    it 'specifies a branch' do
      expect(body[:branch]).to eq('flurb')
    end

    it 'stubs in some config bits' do
      expect(body[:config]).to include(
        language: 'generic',
        dist: 'trusty',
        group: 'edge',
        sudo: true
      )
    end

    it 'contains an env matrix with each builder and template' do
      expect(body[:config][:env][:matrix])
        .to eq(%w(BUILDER=blastoise BUILDER=bulbasaur))
    end

    it 'contains an install step that clones packer-templates' do
      expect(body[:config][:install]).to include(
        /git clone.*packer-templates\.git/
      )
      expect(body[:config][:install]).to include(
        /git checkout -qf afafafa/
      )
    end

    it 'contains an install step that runs bin/packer-build-install' do
      expect(body[:config][:install]).to include(
        %r{\./packer-templates/bin/packer-build-install}
      )
    end

    it 'contains a script step that runs bin/packer-build-script' do
      expect(body[:config][:script]).to eq(
        './packer-templates/bin/packer-build-script flurb'
      )
    end
  end
end
