module Travis
  module PackerBuild
    class GitRoot
      def initialize(commit_range: %w[@ @], branch: '',
                     dir: '', remote: '')
        @commit_range = commit_range
        @branch = branch
        @dir = dir
        @remote = remote
      end

      attr_reader :commit_range, :branch, :dir, :remote
    end
  end
end
