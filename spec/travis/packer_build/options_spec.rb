require 'travis/packer_build/options'

describe Travis::PackerBuild::Options do
  %w(
    chef_cookbook_path
    packer_templates_path
    root_repo
    root_repo_dir
    target_repo_slug
    travis_api_url
    travis_api_token
    branch
    request_interval
    commit_range
    clone_tmp
    builders
    noop
    quiet
  ).each do |attr|
    it("has a #{attr} attr") { subject.public_send(attr) }
  end
end
