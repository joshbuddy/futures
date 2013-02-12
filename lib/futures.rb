module Futures

  class Value

    TimeoutError = Class.new(RuntimeError)

    def read(timeout = nil)
      unless defined?(@value)
        @write = Thread.new { Thread.stop }
        @write.join(timeout) or raise(TimeoutError.new)
      end
      @value
    end

    def write(value)
      @value = value
      @write.wakeup if @write
    end
  end

  def self.included(cls)
    cls.class_eval "
      class << self
        include Futures::ClassMethods
      end
    "
  end

  module ClassMethods
    def future(*attrs)
      attrs.each do |attr|
        self.class_eval "
          def #{attr}(timeout = nil)
            @__#{attr}_future ||= Futures::Value.new
            @__#{attr}_future.read(timeout)
          end

          def #{attr}=(val)
            @__#{attr}_future ||= Futures::Value.new
            @__#{attr}_future.write(val)
          end

        "
      end
    end
  end

end


