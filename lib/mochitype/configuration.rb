# typed: true
require 'sorbet-runtime'

module Mochitype
  class Configuration
    extend T::Sig

    sig { returns(String) }
    attr_accessor :watch_path

    sig { returns(String) }
    attr_accessor :output_path

    sig { void }
    def initialize
      @watch_path = T.let('app/mochitypes/', String) # default path for Sorbet files
      @output_path = T.let('app/javascript/__generated__/mochitypes', String) # default path for TypeScript output
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def configuration
      @configuration ||= Configuration.new
    end

    sig { params(blk: T.proc.params(config: Configuration).void).void }
    def configure(&blk)
      yield(configuration)
    end

    sig { void }
    def start_watcher!
      Mochitype::FileWatcher.start
    end
  end
end
