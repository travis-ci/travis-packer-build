require 'faraday'

require 'travis/packer_build/cli'

Halp = Class.new(StandardError)

describe Travis::PackerBuild::Cli do
  subject { described_class.new }

  let(:api_token) { 'flubber' }
  let(:git_diff_files) { [] }
  let(:here) { File.expand_path('../../../../', __FILE__) }
  let(:fake_detector) { double('fake_detector') }

  let :argv do
    %W(
      --quiet
      --chef-cookbook-path=#{here}/.git::cookbooks
      --packer-templates-path=#{here}/.git::cookbooks
      --target-repo-slug=serious-business/verybigapplication
      --github-api-token=SOVERYSECRET
      --commit-range=fafafaf...afafafa
      --branch=twig
      --default-builders=bob,wendy,pickles
    )
  end

  let :fake_github_requester do
    instance_double(
      'Travis::PackerBuild::GithubRequester',
      :fake_github_requester,
      perform: true
    )
  end

  let :fake_templates do
    [
      instance_double(
        'Travis::PackerBuild::PackerTemplate',
        :wooker,
        name: 'wooker',
        filename: 'wooker.yml',
        parsed: {
          'builders' => [
            {
              'type' => 'googlecompute'
            },
            {
              'type' => 'amazon-ebs'
            }
          ]
        }
      ),
      instance_double(
        'Travis::PackerBuild::PackerTemplate',
        :dippity,
        name: 'dippity',
        filename: 'dippity.json',
        parsed: {
          'builders' => [
            {
              'type' => 'docker'
            }
          ]
        }
      )
    ]
  end

  let :fake_git_repo do
    instance_double(
      'Git::Base',
      :fake_git_repo
    )
  end

  let :fake_git_remote_path_parser do
    instance_double(
      'Travis::PackerBuild::GitRemotePathParser',
      :fake_git_remote_path_parser,
      parse: [
        instance_double(
          'Travis::PackerBuild::GitPath',
          :pathy_path,
          repo: fake_git_repo
        )
      ]
    )
  end

  before :each do
    allow(fake_git_repo).to receive_message_chain('repo.path') { '.git' }
    allow_any_instance_of(described_class)
      .to receive(:github_requester).and_return(fake_github_requester)
    allow(subject.send(:options))
      .to receive(:github_api_token).and_return(api_token)
    allow(subject.send(:options))
      .to receive(:commit_range).and_return(%w(fafafaf afafafa))
    allow_any_instance_of(described_class)
      .to receive(:changed_files).and_return(git_diff_files)
    allow_any_instance_of(described_class)
      .to receive(:commit_message).and_return('flea flah flew')
    allow_any_instance_of(described_class)
      .to receive(:git_remote_path_parser)
      .and_return(fake_git_remote_path_parser)
    allow(subject.send(:options)).to receive(:default_builders)
      .and_return(%w(fribble schnozzle))
    allow(subject).to receive(:detectors).and_return([fake_detector])
    allow(fake_detector).to receive(:detect).and_return(fake_templates)
  end

  it 'is helpful' do
    allow(subject).to receive(:exit).and_raise(Halp)
    expect { subject.run(argv: %w(--help)) }.to raise_error(Halp)
  end

  it 'may be run via .run!' do
    allow_any_instance_of(described_class).to receive(:run).and_return(86)
    expect(described_class.run!(argv: argv)).to eq(86)
  end

  it 'may be run via #run' do
    expect(subject.run(argv: argv)).to eq(0)
  end

  describe 'requests' do
    let :requests do
      subject.send(:setup, argv)
      subject.send(:build_requests)
    end

    it 'creates a request for each template' do
      expect(requests.size).to eq(2)
    end
  end
end
