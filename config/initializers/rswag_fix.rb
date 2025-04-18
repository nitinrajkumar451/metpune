begin
  require "rswag/api"
  require "rswag/ui"
rescue LoadError => e
  puts "Error loading Rswag gems: #{e.message}"
end

unless Object.const_defined?("Rswag")
  module Rswag
    module Api
      class Engine < ::Rails::Engine
        isolate_namespace Rswag::Api
      end

      module Configuration
        attr_accessor :openapi_root
        attr_accessor :swagger_filter

        def self.extended(base)
          base.openapi_root = nil
          base.swagger_filter = nil
        end
      end

      def self.configure
        yield self
      end

      extend Configuration
    end

    module Ui
      class Engine < ::Rails::Engine
        isolate_namespace Rswag::Ui
      end

      module Configuration
        attr_accessor :config

        def self.extended(base)
          base.config = {}
        end
      end

      def self.configure
        yield self
      end

      def self.swagger_endpoint(path, title)
        config[path] = title
      end

      extend Configuration
    end
  end
end
