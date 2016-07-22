require 'travis/packer_build/request'

describe Travis::PackerBuild::Request do
  %w(
    branch
    config
    message
  ).each do |attr|
    it("has a #{attr} attr") { subject.public_send(attr) }
  end
end
