# frozen_string_literal: true

require 'travis/packer_build/request_builder'

describe Travis::PackerBuild::RequestBuilder do
  subject do
    described_class.new(
      default_builders: %w[blastoise bulbasaur],
      body_vars: {},
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
  it 'has a branch' do
    requests.each do |_, request|
      expect(request.branch).to_not be_empty
    end
  end

  it 'has a message' do
    requests.each do |_, request|
      expect(request.message).to match(/:bomb:/)
    end
  end

  it 'specifies a branch' do
    requests.each do |_, request|
      expect(request.branch).to match(/flurb|larping/)
    end
  end

  it 'stubs in some config bits' do
    requests.each do |_, request|
      expect(request.config).to include(
        'language' => 'generic',
        'dist' => 'xenial',
        'group' => 'edge',
        'sudo' => true
      )
    end
  end

  it 'contains an env matrix with each builder and template' do
    expect(requests.map { |_, r| r.config['env']['matrix'] }.sort)
      .to eq([%w[BUILDER=amazon-ebs BUILDER=dooker], %w[BUILDER=gce]])
  end
end
