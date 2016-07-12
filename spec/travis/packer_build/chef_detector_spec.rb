require 'travis/packer_build/chef_detector'

describe Travis::PackerBuild::ChefDetector do
  subject do
    described_class.new(
      [fake_cookbook_path_entry],
      [fake_packer_templates_path_entry],
      fake_log
    )
  end

  let(:fake_cookbook_path_entry) { double('fake_cookbook_path_entry') }

  let(:fake_packer_templates_path_entry) do
    double('fake_packer_templates_path_entry')
  end

  let(:fake_log) { instance_double('Logger', info: true) }

  let :fake_packer_templates do
    {
      instance_double(
        'Travis::PackerBuild::PackerTemplate',
        name: 'world1-3',
        filename: 'blorp::world1-3.yml'
      ) => %w(wendy lemmy larry roy),
      instance_double(
        'Travis::PackerBuild::PackerTemplate',
        name: 'world8-2',
        filename: 'blorp::world8-2.yml'
      ) => %w(wendy morton ludwig lemmy)
    }
  end

  let(:fake_cookbooks) do
    instance_double(
      'Travis::PackerBuild::ChefCookbooks',
      files: %w(
        cookbooks/wendy/recipes/default.rb
        cookbooks/wendy/attributes/default.rb
        cookbooks/wendy/metadata.rb
      ).map do |p|
        instance_double(
          'Travis::PackerBuild::GitPath',
          path: p,
          namespaced_path: "blorp::#{p}"
        )
      end
    )
  end

  before :each do
    allow(subject).to receive(:packer_templates)
      .and_return(fake_packer_templates)
    allow(subject).to receive(:cookbooks).and_return(fake_cookbooks)
  end

  it 'returns an empty array for no git paths' do
    expect(subject.detect([])).to eql([])
  end

  it 'detects when template changes' do
    expect(
      subject.detect(
        [
          instance_double(
            'Travis::PackerBuild::GitPath',
            path: 'world1-3.yml',
            namespaced_path: 'blorp::world1-3.yml'
          )
        ]
      )
    ).to eql(%w(world1-3))
  end
end
