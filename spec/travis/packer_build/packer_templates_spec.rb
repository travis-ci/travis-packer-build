# frozen_string_literal: true

require 'travis/packer_build/packer_templates'

describe Travis::PackerBuild::PackerTemplates do
  subject do
    described_class.new([fake_packer_templates_path])
  end

  let :fake_packer_templates_path do
    instance_double(
      'Travis::PackerBuild::GitPath',
      :fake_packer_templates_path
    )
  end

  let :template_files do
    [
      instance_double(
        'Travis::PackerBuild::GitPath',
        :wizards_yml,
        namespaced_path: 'lol@bud.git::cave/wizards.yml',
        show: "$,%\x0dont_even: []\nnorly: True\n"
      ),
      instance_double(
        'Travis::PackerBuild::GitPath',
        :witches_yml,
        namespaced_path: 'lol@bud.git::coven/witches.json',
        show: '{"variables": "no", "builders": "maybe", "lol": "nope"}'
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
      pattern.source.match?(/\\\.\(yml\|json\)\$/) ? template_files : []
    end
  end

  it 'allows for eaching over templates by name' do
    all_templates = Array(subject.each)
    expect(all_templates.length).to eq(1)
    expect(all_templates.first.first).to eq('birthday_cake')
  end
end
