require 'travis/packer_build/options'

describe Travis::PackerBuild::Options do
  %w(
    body_tmpl
    branch
    builders
    chef_cookbook_path
    clone_tmp
    commit_range
    noop
    packer_templates_path
    quiet
    request_interval
    root_repo
    root_repo_dir
    target_repo_slug
    travis_api_token
    travis_api_url
  ).each do |attr|
    it("has a #{attr} attr") { subject.public_send(attr) }
  end
end
