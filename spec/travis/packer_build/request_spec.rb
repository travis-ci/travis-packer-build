require 'travis/packer_build'

describe Travis::PackerBuild::Request do
  %w(
    url
    body
    headers
  ).each do |attr|
    it("has a #{attr} attr") { subject.public_send(attr) }
  end
end
