# frozen_string_literal: true

module Travis
  module PackerBuild
    class Request
      attr_accessor :message, :config, :branch

      def to_s
        "<#{self.class.name} message=#{message.inspect} " \
          "config=#{config.inspect} branch=#{branch.inspect}>"
      end
    end
  end
end
