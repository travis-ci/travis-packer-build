# frozen_string_literal: true

require 'travis/packer_build/chef_dependency_finder'

describe Travis::PackerBuild::ChefDependencyFinder do
  subject do
    described_class.new(fake_run_list, [fake_cookbook_path_entry])
  end

  let(:fake_run_list) { %w(recipe[tofurkey::hotpot) }
  let(:fake_cookbook_path_entry) { double('cookbook_path_entry') }
  let(:tofurkey_recipes_default) { double('tofurkey_recipes_default') }
  let(:tofurkey_recipes_unicorn) { double('tofurkey_recipes_unicorn') }
  let :tofurkey_recipes do
    [
      tofurkey_recipes_default,
      tofurkey_recipes_unicorn
    ]
  end

  before :each do
    allow(fake_cookbook_path_entry).to receive(:files)
      .with(%r{.+/tofurkey/recipes/[^/]+\.rb})
      .and_return(tofurkey_recipes)
    allow(tofurkey_recipes_default).to receive(:show)
      .and_return(<<~RECIPE)
        include_recipe 'beancurd::firm'
        include_recipe 'imagination'
      RECIPE
    allow(tofurkey_recipes_unicorn).to receive(:show)
      .and_return(<<~RECIPE)
        include_recipe 'beancurd::enchanted'

        log('whatebber') { level :hello }

        cookbook_file 'horns.txt' do
          user 'beelzebub'
        end

        1 / 0
      RECIPE
    allow(tofurkey_recipes_unicorn).to receive(:namespaced_path)
      .and_return('git@nope:ohai.git::cookbooks/tofurkey/recipes/unicorn.rb')
  end

  it 'finds dependencies' do
    expect(subject.find).to eql(%w[beancurd imagination tofurkey])
  end
end
