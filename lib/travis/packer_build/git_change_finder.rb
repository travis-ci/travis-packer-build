require 'fileutils'
require 'logger'

require 'git'

module Travis
  module PackerBuild
    class GitChangeFinder
      def initialize(commit_range: %w(@ @), root_repo: '',
                     clone_tmp: '', git_paths: [], git_logger: nil,
                     dig_through_git_paths: false)
        @commit_range = commit_range
        @root_repo = root_repo
        @clone_tmp = clone_tmp
        @git_paths = git_paths
        @git_logger = git_logger
        @dig_through_git_paths = dig_through_git_paths
      end

      def find
        changed_paths = changed_paths_in_range(
          root_repo_git, commit_range.first, commit_range.last
        )

        return changed_paths unless dig_through_git_paths

        start_date = root_repo_git.gcommit(commit_range.first).date
        finish_date = root_repo_git.gcommit(commit_range.last).date

        git_paths.each do |entry|
          range_start = entry.repo.log(100).since(start_date).last.sha
          range_finish = entry.repo.log(100).select do |commit|
            commit.date >= finish_date
          end.last
          range_finish = entry.repo.log(1).last.sha if range_finish.nil?

          changed_paths += changed_paths_in_range(
            entry.repo, range_start, range_finish
          )
        end

        changed_paths
      end

      private

      attr_reader :commit_range, :root_repo, :git_paths, :clone_tmp
      attr_reader :dig_through_git_paths

      def changed_paths_in_range(git, start, finish)
        git.gtree(start).diff(finish).name_status
           .select { |_, s| %w(M A).include?(s) }
           .map do |f, _|
          Travis::PackerBuild::GitPath.new(root_repo_git, f, finish)
        end
      end

      def root_repo_git
        Git.bare(root_repo_dir, log: git_logger)
      end

      def root_repo_dir
        return @root_repo_dir if @root_repo_dir &&
                                 File.exist?(@root_repo_dir)
        @root_repo_dir = clone_root_repo
      end

      def root_repo_origin_url
        root_repo_git.remotes
                     .select { |remote| remote.name == 'origin' }.first.url
      end

      def clone_root_repo
        dest = File.join(clone_tmp, '__root__.git')

        if File.directory?(dest)
          Git.bare(dest, log: git_logger).fetch('origin')
          return dest
        end

        Git.clone(root_repo, dest, bare: true)

        dest
      end

      def clone_tmp
        return @clone_tmp if @clone_tmp && File.directory?(@clone_tmp)
        FileUtils.mkdir_p(@clone_tmp)
        @clone_tmp
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
