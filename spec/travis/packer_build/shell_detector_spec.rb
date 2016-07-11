require 'travis/packer_build'

describe Travis::PackerBuild::ShellDetector do
  subject { described_class.new([fake_packer_templates_path], fake_log) }

  let :fake_packer_templates_path do
    instance_double(
      'Travis::PackerBuild::GitPath',
      :fake_packer_templates_path
    )
  end

  let :fake_packer_templates do
    {
      'baseybase' => instance_double(
        'Travis::PackerBuild::PackerTemplate', :baseybase,
        name: 'cakes',
        filename: 'cakes.yml',
        parsed: {
          'provisioners' => [
            {
              'type' => 'shell',
              'scripts' => %w(noises/boom)
            }
          ]
        }
      ),
      'veryspecial' => instance_double(
        'Travis::PackerBuild::PackerTemplate', :veryspecial,
        name: 'breads',
        filename: 'breads.yml',
        parsed: {
          'provisioners' => [
            {
              'type' => 'shell',
              'inline' => %w(echo go jump in a lake)
            },
            {
              'type' => 'shell',
              'script' => 'noises/boom'
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

  let(:fake_log) { instance_double('Logger', info: true) }

  before :each do
    allow(subject).to receive(:packer_templates)
      .and_return(fake_packer_templates)
    allow(fake_packer_templates_path).to receive(:files) do |regex|
      if regex.source =~ %r{noises/}
        [
          instance_double(
            'Travis::PackerBuild::GitPath', :boom,
            path: 'noises/boom',
            namespaced_path: 'boing:noises/boom'
          )
        ]
      else
        [
          instance_double(
            'Travis::PackerBuild::GitPath', :boom,
            path: 'razza/frazza/lets/go/shopping',
            namespaced_path: 'boing:razza/frazza/lets/go/shopping'
          )
        ]
      end
    end
  end

  it 'responds with an empty array when no git paths are given' do
    expect(subject.detect([])).to eq([])
  end

  it 'detects when shell provisioner files change' do
    expect(
      subject.detect(
        %w(
          noises/boom
          special/conf/files/secret-squirrel.conf
          controversial-foods/pastrami
        ).map do |p|
          instance_double(
            'Travis::PackerBuild::GitPath',
            path: p,
            namespaced_path: "boing:#{p}"
          )
        end
      )
    ).to eql(%w(breads cakes))
  end
end
