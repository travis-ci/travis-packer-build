# frozen_string_literal: true

require 'travis/packer_build/chef_fake_recipe_methods'

describe Travis::PackerBuild::ChefFakeRecipeMethods do
  subject do
    Class.new do
      include Travis::PackerBuild::ChefFakeRecipeMethods
    end.new
  end

  it 'accumulates included recipe names' do
    subject.include_recipe 'toaster::pastry'
    subject.include_recipe 'magic::beans'
    expect(subject.instance_variable_get(:@included_recipes))
      .to eq(%w[toaster::pastry magic::beans])
  end

  it 'allows for arbitrary depth node traversal' do
    expect(subject.node['name']['spaces']['are']['my'].life)
      .to_not be_nil
  end

  it 'hash a hashy Chef::Config' do
    expect(subject.class::Chef::Config['huh']).to_not be_nil
  end

  it 'black holes missing consts' do
    expect(
      subject.class::Whats.new(subject.class::How.ya_been)
    ).to_not be_nil

    # This one is a bit of a special case, and should probably be removed
    # at some point mayyyybe
    expect(
      subject.class::TravisPackerTemplates.init!(subject.node)
    ).to_not be_nil
  end

  it 'does not explode when evaluating recipes' do
    recipe = <<~RECIPE.gsub(/^\s+> ?/, '')
      include_recipe 'toaster::avocado'
      include_recipe 'frivolous::consumerism'

      log('something important') { level :warn }

      cookbook_file 'critical.conf' do
        user 'root'
        group 'root'
        mode 0400
      end

      ArbitraryThing.new(node['lolwut'].sers).wheeeeee!

      if Chef::Config[node['is']['it']['not']['true'].that.i.am.fancy]
        ark 'enterprise-monolith' do
          somewhere 'what'
        end
      end

      :made_it
    RECIPE
    expect(subject.instance_eval(recipe)).to eq(:made_it)
    expect(subject.instance_variable_get(:@included_recipes))
      .to eq(%w[toaster::avocado frivolous::consumerism])
  end
end
