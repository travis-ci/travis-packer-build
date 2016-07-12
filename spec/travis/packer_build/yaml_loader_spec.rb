require 'travis/packer_build/yaml_loader'

describe Travis::PackerBuild::YamlLoader do
  subject { described_class }

  it 'loads yaml' do
    expect(subject.load_string('is_this: thing on')).to eq(
      'is_this' => 'thing on'
    )
  end

  it 'loads yaml with erb bits' do
    yaml = <<-EOYAML.gsub(/^\s+> ?/, '')
      > <% if true %>
      > noodles: delicious
      > <% else %>
      > noodles: worms
      > <% end %>
      > <% %w(olaf marshmallow).each do |s| %>
      > <%= s %>_composition: snowy
      > <% end %>
    EOYAML
    expect(subject.load_string(yaml)).to eq(
      'noodles' => 'delicious',
      'olaf_composition' => 'snowy',
      'marshmallow_composition' => 'snowy'
    )
  end

  it 'explodes on invalid yaml' do
    expect { subject.load_string("$-~\x0") }.to raise_error(RuntimeError)
  end

  it 'explodes on invalid erb' do
    expect do
      subject.load_string("foo: bar\n<%= nope %>")
    end.to raise_error(NameError)
  end
end
