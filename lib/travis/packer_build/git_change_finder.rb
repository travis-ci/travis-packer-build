require 'fileutils'
require 'logger'
require 'tmpdir'

require 'git'

require_relative 'git_path'

module Travis
  module PackerBuild
    class GitChangeFinder
      def initialize(root: nil, clone_tmp: '', packer_templates_path: [],
                     git_logger: nil)
        @root = root
        @clone_tmp = clone_tmp
        @packer_templates_path = packer_templates_path
        @git_logger = git_logger
      end

      def find
        changed = changed_paths_in_range(
          root_repo_git, root.commit_range.first, root.commit_range.last
        )

        # FIXME: worth pursuing??
        # range_start = root_repo_git.gcommit(root.commit_range.first).date
        # range_finish = root_repo_git.gcommit(root.commit_range.last).date

        # packer_templates.each do |_, template|
        #   template.git_paths.each do |entry|
        #     changed += changed_paths_in_range(
        #       entry.repo, *commit_range_for_date_range(
        #         entry.repo, range_start, range_finish
        #       )
        #     )
        #   end
        # end

        changed
      end

      private

      attr_reader :root, :packer_templates_path

      def changed_paths_in_range(git, start, finish)
        git.gtree(start).diff(finish).name_status
           .select { |_, s| %w(M A).include?(s) }
           .map do |f, _|
          Travis::PackerBuild::GitPath.new(git, f, finish)
        end
      end

      # def commit_range_for_date_range(git, start, finish)
      #   range = (
      #     Array(git.log(1_000).since(start)) & Array(git.log(1_000).until(finish))
      #   )
      #   [range.last.sha, range.first.sha]
      # end

      def root_repo_git
        Git.bare(root_repo_dir, log: git_logger)
      end

      def root_repo_dir
        return root.dir if root.dir && File.exist?(root.dir)
        root.dir = clone_root_repo
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

        Git.clone(root.remote, dest, bare: true)

        dest
      end

      def clone_tmp
        return @clone_tmp if @clone_tmp && File.directory?(@clone_tmp)
        @clone_tmp = File.join(Dir.tmpdir, 'travis-packer-build')
        FileUtils.mkdir_p(@clone_tmp)
        @clone_tmp
      end

      # def packer_templates
      #   @packer_templates ||= Travis::PackerBuild::PackerTemplates.new(
      #     packer_templates_path
      #   )
      # end

      def git_logger
        @git_logger ||= Logger.new($stderr).tap do |l|
          l.level = Logger::FATAL
          l.level = Logger::DEBUG if @debug
        end
      end
    end
  end
end
