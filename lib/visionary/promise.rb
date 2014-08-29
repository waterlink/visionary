module Visionary
  class Promise

    class << self
      def setup!
        unless setted_up
          Kernel.send :define_method, :promise do
            Promise.new
          end
          self.setted_up = true
        end
      end

      private

      attr_accessor :setted_up
    end

    def future
      @future ||= Future.new
    end

    def complete(computed_value)
      future.instance_eval { complete_with(computed_value) }
      freeze
    end

    def fail(provided_error)
      future.instance_eval { fail_with(provided_error) }
      freeze
    end

  end
end
