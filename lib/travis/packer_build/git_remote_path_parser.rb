require 'logger'
require 'tmpdir'

require 'git'

require_relative 'git_path'

module Travis
  module PackerBuild
    class GitRemotePathParser
      def initialize(clone_tmp: File.join(Dir.tmpdir, 'downstreams-clones'),
                     git_logger: nil)
        @clone_tmp = clone_tmp
        @git_logger = git_logger
      end

      def parse(string)
        entries = string.split(/\s+/).map do |segment|
          repo_remote, paths = segment.split('::')
          paths = '/' unless paths
          local_clone = File.join(repo_remote, '.git')

          if File.directory?(local_clone)
            repo_remote = Git.bare(local_clone, log: git_logger).remotes
                             .select { |remote| remote.name == 'origin' }
                             .first.url
          else
            local_clone = File.join(
              clone_tmp, clone_basename(repo_remote)
            )
          end

          if File.directory?(local_clone)
            git = load_bare(local_clone)
            git.fetch
          else
            git = clone_bare(repo_remote, local_clone)
          end

          paths.split(',').map do |path_entry|
            entry, ref = path_entry.split('@').map(&:strip)
            ref = '@' unless ref
            Travis::PackerBuild::GitPath.new(git, entry.sub(%r{^/}, ''), ref)
          end
        end

        entries.flatten
      end

      private

      attr_reader :clone_tmp

      def clone_bare(repo_remote, local_clone)
        Git.clone(repo_remote, local_clone, bare: true, log: git_logger)
      end

      def load_bare(local_clone)
        Git.bare(local_clone, log: git_logger)
      end

      def clone_basename(repo_remote)
        URI.escape(repo_remote, '@:/.') + '.git'
      end

      def git_logger
        @git_logger ||= Logger.new($stderr).tap do |l|
          l.level = Logger::FATAL
          l.level = Logger::DEBUG if @debug
        end
      end
    end
  end
end
