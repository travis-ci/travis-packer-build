# frozen_string_literal: true

require 'travis/packer_build/chef_packer_templates'

describe Travis::PackerBuild::ChefPackerTemplates do
  subject do
    described_class.new(
      [fake_cookbook_path_entry],
      [fake_packer_templates_path_entry]
    )
  end

  let :fake_cookbook_path_entry do
    instance_double(
      'Travis::PackerBuild::GitPath',
      :fake_cookbook_path_entry
    )
  end

  let :fake_packer_templates_path_entry do
    instance_double(
      'Travis::PackerBuild::GitPath',
      :fake_packer_templates_path_entry
    )
  end

  let :fake_packer_templates do
    {
      'baseybase' => instance_double(
        'Travis::PackerBuild::PackerTemplate', :baseybase,
        name: 'baseybase',
        filename: 'baseybase.yml',
        parsed: {
          'provisioners' => [
            {
              'type' => 'chef-solo',
              'run_list' => %w(
                recipe[hambro::castle]
                recipe[lake_ruin::munster]
              )
            }
          ]
        }
      ),
      'delish' => instance_double(
        'Travis::PackerBuild::PackerTemplate', :delish,
        name: 'delish',
        filename: 'delish.yml',
        parsed: {
          'provisioners' => [
            {
              'type' => 'chef-solo',
              'run_list' => %w(
                recipe[goodbar]
                recipe[snicker]
                recipe[musketeer]
              )
            }
          ]
        }
      ),
      'justdont' => instance_double(
        'Travis::PackerBuild::PackerTemplate', :justdont,
        name: 'justdont',
        filename: 'how/did/you/find/me/justdont.yml',
        parsed: { 'provisioners' => [] }
      )
    }
  end

  let :fake_dependencies do
    {
      'recipe[goodbar]' => %w[
        chalklit
        peanit
      ],
      'recipe[snicker]' => %w[
        chalklit
        peanit
        carmul
        noogit
      ],
      'recipe[musketeer]' => %w[
        chalklit
        flooof
      ]
    }
  end

  before :each do
    allow(subject).to receive(:packer_templates)
      .and_return(fake_packer_templates)
    allow(subject).to receive(:find_dependencies) do |run_list, _|
      deps = run_list.map { |r| r.split(/[\[\]]/).last.sub(/::.*/, '') }
      deps += run_list.map { |r| fake_dependencies[r] }
      deps.flatten.compact.sort.uniq
    end
  end

  it 'loads all cookbooks by template' do
    loaded = Hash[Array(subject.each)]
    expect(loaded).to_not be_empty
    expect(loaded).to eq(
      fake_packer_templates['baseybase'] => %w[
        hambro
        lake_ruin
      ],
      fake_packer_templates['delish'] => %w[
        carmul
        chalklit
        flooof
        goodbar
        musketeer
        noogit
        peanit
        snicker
      ]
    )
  end
end
