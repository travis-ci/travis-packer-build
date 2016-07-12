require 'travis/packer_build/file_detector'

describe Travis::PackerBuild::FileDetector do
  subject { described_class.new([fake_packer_templates_path], fake_log) }

  let :fake_packer_templates_path do
    instance_double('Travis::PackerBuild::GitPath', :packer_templates_path)
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
              'type' => 'file',
              'source' => 'important/files/critical.txt'
            }
          ]
        }
      ),
      'veryspecial' => instance_double(
        'Travis::PackerBuild::PackerTemplate', :veryspecial,
        name: 'veryspecial',
        filename: 'veryspecial.json',
        parsed: {
          'provisioners' => [
            {
              'type' => 'file',
              'source' => 'important/files/critical.txt'
            },
            {
              'type' => 'file',
              'source' => 'important/files/secret-salsa'
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

  let(:fake_log) { instance_double('Logger', :log, info: true) }

  before :each do
    allow(subject).to receive(:packer_templates)
      .and_return(fake_packer_templates)
    allow(fake_packer_templates_path).to receive(:files) do |regex|
      if regex.to_s =~ %r{important/files}
        [
          instance_double(
            'Travis::PackerBuild::GitPath', :critical_txt,
            path: 'important/files/critical.txt',
            namespaced_path: 'flimflam:important/files/critical.txt'
          )
        ]
      else
        [
          instance_double(
            'Travis::PackerBuild::GitPath', :bonus_log,
            path: 'why/was/this/committed/bonus.log',
            namespaced_path: 'flimflam:why/was/this/committed/bonus.log'
          )
        ]
      end
    end
  end

  it 'responds with an empty array when no git paths are given' do
    expect(subject.detect([])).to eq([])
  end

  it 'detects when file provisioner inputs change' do
    expect(
      subject.detect(
        %w(
          important/files/critical.txt
          why/was/this/committed/bonus.log
        ).map do |p|
          instance_double(
            'Travis::PackerBuild::GitPath',
            path: p,
            namespaced_path: "flimflam:#{p}"
          )
        end
      ).map(&:name)
    ).to eql(%w(baseybase veryspecial))
  end
end
