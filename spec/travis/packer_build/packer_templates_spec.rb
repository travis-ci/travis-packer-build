require 'travis/packer_build'

describe Travis::PackerBuild::PackerTemplates do
  subject do
    described_class.new([fake_packer_templates_path])
  end

  let :fake_packer_templates_path do
    instance_double(
      'Travis::PackerBuild::GitPath',
      :fake_packer_templates_path,
    )
  end

  let :yml_files do
    [
      instance_double(
        'Travis::PackerBuild::GitPath',
        :wizards_yml,
        namespaced_path: 'lol@bud.git::cave/wizards.yml',
        show: "dont_even: []\nnorly: True\n"
      ),
      instance_double(
        'Travis::PackerBuild::GitPath',
        :witches_yml,
        namespaced_path: 'lol@bud.git::coven/witches.yml',
        show: "variables: no\nbuilders: maybe\nlol: nope\n"
      ),
      instance_double(
        'Travis::PackerBuild::GitPath',
        :birthday_cake_yml,
        namespaced_path: 'lol@bud.git::birthday_cake.yml',
        show: "variables:\n  canders: 9\nbuilders: []\nprovisioners: []\n"
      )
    ]
  end

  before :each do
    allow(fake_packer_templates_path).to receive(:files) do |pattern|
      pattern.to_s =~ /\.yml$/ ? yml_files : []
    end
  end
end
