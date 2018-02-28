# frozen_string_literal: true

require 'travis/packer_build/github_requester'
require 'travis/packer_build/request'

describe Travis::PackerBuild::GithubRequester do
  subject do
    described_class.new(
      github_api_token: 'fabbafabbababa00000', repo_slug: 'dancing/bear'
    )
  end

  let :fake_gh do
    instance_double(
      'GH::Remote',
      :fake_gh
    )
  end

  before :each do
    allow(subject).to receive(:gh).and_return(fake_gh)
    allow(fake_gh).to receive(:[]).with('repos/dancing/bear')
                                  .and_return(
                                    '_links' => {
                                      'self' => {
                                        'href' => 'https://api.github.com/repositories/12345678?per_page=100'
                                      }
                                    }
                                  )
    allow(fake_gh).to receive(:[])
      .with('repositories/12345678/git/refs/heads/meistersons')
      .and_return(
        'object' => {
          'sha' => 'fafafafbababab'
        }
      )
    allow(fake_gh).to receive(:[])
      .with('repositories/12345678/git/commits/fafafafbababab')
      .and_return(
        'tree' => {
          'sha' => 'fafafaf90909001'
        }
      )
    allow(fake_gh).to receive(:post)
      .with(
        'repositories/12345678/git/blobs',
        '{"content":"---\\nscript: echo whatebber\\n"}'
      )
      .and_return(
        'sha' => 'fafafafac9ac9ac'
      )
    allow(fake_gh).to receive(:post)
      .with(
        'repositories/12345678/git/trees',
        '{"base_tree":"fafafaf90909001","tree":[{"type":"blob","path":' \
        '".travis.yml","mode":"100644","sha":"fafafafac9ac9ac"}]}'
      )
      .and_return(
        'sha' => 'fafafafba4ba4ba4'
      )
    allow(fake_gh).to receive(:post)
      .with(
        'repositories/12345678/git/commits',
        '{"tree":"fafafafba4ba4ba4","parents":["fafafafbababab"],' \
        '"message":":boom: ohai"}'
      )
      .and_return(
        'sha' => 'fafafaf3ea3ea3ea'
      )
    allow(fake_gh).to receive(:patch)
      .with(
        'repositories/12345678/git/refs/heads/meistersons',
        '{"sha":"fafafaf3ea3ea3ea"}'
      )
      .and_return('ok' => 'sure')
  end

  it 'performs requests' do
    req = Travis::PackerBuild::Request.new
    req.message = ':boom: ohai'
    req.config = { 'script' => 'echo whatebber' }
    req.branch = 'meistersons'
    expect(subject.perform(req)).to be_truthy
  end
end
