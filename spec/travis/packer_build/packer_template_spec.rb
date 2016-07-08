require 'travis/packer_build'

describe Travis::PackerBuild::PackerTemplate do
  subject do
    described_class.new(
      'lol@wut.git::subdir/mania/happy-dog.yml',
      <<-EOF.gsub(/^\s+> ?/, '')
        > variables:
        >   wheel: ferris
        >   noodle: farfalle
        >   patty: falafel
        > builders:
        > - type: docker
        >   name: dooker
        > provisioners:
        > - type: file
        >   source: fancy/path.txt
        >   destination: /var/tmp/boom
        > - type: shell
        >   scripts:
        >   - runthis/plz
        > - type: chef-solo
        >   run_list:
        >   - howdy::doo
      EOF
    )
  end

  it 'has a name' do
    expect(subject.name).to eq('happy-dog')
  end

  it 'has a filename' do
    expect(subject.filename).to eq('lol@wut.git::subdir/mania/happy-dog.yml')
  end

  it 'has a parsed representation' do
    expect(subject.parsed).to include('variables')
    expect(subject.parsed).to include('builders')
    expect(subject.parsed).to include('provisioners')
  end
end
