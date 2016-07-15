require 'travis/packer_build/request_builder'

describe Travis::PackerBuild::RequestBuilder do
  subject do
    described_class.new(
      travis_api_token: 'wherps',
      target_repo_slug: 'serious/application',
      default_builders: %w(blastoise bulbasaur),
      commit_range: %w(fafafaf afafafa),
      branch: 'meister'
    )
  end

  let :fake_templates do
    [
      instance_double(
        'Travis::PackerBuild::PackerTemplate',
        :larping,
        name: 'larping',
        filename: 'larping.json',
        parsed: {
          'builders' => [
            {
              'type' => 'googlecompute',
              'name' => 'gce'
            }
          ]
        }
      ),
      instance_double(
        'Travis::PackerBuild::PackerTemplate',
        :flurb,
        name: 'flurb',
        filename: 'flurb.yml',
        parsed: {
          'builders' => [
            {
              'type' => 'amazon-ebs'
            },
            {
              'type' => 'docker',
              'name' => 'dooker'
            }
          ]
        }
      )
    ]
  end

  let(:requests) { subject.build(fake_templates) }

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
    let(:body) { subject.send(:body, fake_templates.last) }

    it 'has a message with commit' do
      expect(body['message']).to match(/commit-range=fafafaf\.\.\.afafafa/)
    end

    it 'specifies a branch' do
      expect(body['branch']).to eq('flurb')
    end

    it 'stubs in some config bits' do
      expect(body['config']).to include(
        'language' => 'generic',
        'dist' => 'trusty',
        'group' => 'edge',
        'sudo' => true
      )
    end

    it 'contains an env matrix with each builder and template' do
      expect(body['config']['env']['matrix'])
        .to eq(%w(BUILDER=amazon-ebs BUILDER=dooker))
    end
  end
end
