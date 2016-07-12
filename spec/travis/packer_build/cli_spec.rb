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
      --travis-api-url=https://bogus.example.com:9999
      --travis-api-token=SOVERYSECRET
      --commit-range=fafafaf...afafafa
      --branch=twig
      --builders=bob,wendy,pickles
      --request-interval=0
    )
  end

  let :test_http do
    Faraday.new do |faraday|
      faraday.adapter :test, http_stubs
    end
  end

  let :http_stubs do
    Faraday::Adapter::Test::Stubs.new
  end

  let(:response_status) { 201 }
  let(:response_body) { '{"yey":true}' }

  before :each do
    allow_any_instance_of(described_class)
      .to receive(:build_http).and_return(test_http)
    allow(subject.send(:options))
      .to receive(:travis_api_token).and_return(api_token)
    allow(subject.send(:options))
      .to receive(:commit_range).and_return(%w(fafafaf afafafa))
    allow_any_instance_of(described_class)
      .to receive(:changed_files).and_return(git_diff_files)
    %w(
      /repo/serious-business%2Fverybigapplication/requests
      /repo/travis-ci%2Fpacker-build/requests
    ).each do |post_path|
      http_stubs.post(post_path) do |_env|
        [
          response_status,
          { 'Content-Type' => 'application/json' },
          response_body
        ]
      end
    end
    allow(subject.send(:options)).to receive(:builders)
      .and_return(%w(fribble schnozzle))
    allow(subject).to receive(:detectors).and_return([fake_detector])
    allow(fake_detector).to receive(:detect).and_return(%w(wooker dippity))
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

  it 'makes no http requests on noop' do
    expect(test_http).to_not receive(:post)
    subject.run(argv: argv + %w(--noop))
  end

  context 'when response status is > 299' do
    let(:response_status) { 403 }
    let(:response_body) { '{"error":"there is no try"}' }

    it 'counts it as an error' do
      logged = []
      allow(subject.send(:log)).to receive(:info) do |*args|
        logged << args
      end
      subject.run(argv: argv)
      expect(logged).to include(['All done! triggered=0 errored=2'])
    end
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
