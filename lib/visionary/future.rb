module Visionary
  class Future

    class << self
      def setup!
        unless setted_up
          Kernel.send :define_method, :future do |&blk|
            Future.new(&blk).run
          end
          self.setted_up = true
        end
      end

      private

      attr_accessor :setted_up
    end

    attr_reader :state, :error, :value

    def initialize(&blk)
      @block = blk
      self.state = :pending
    end

    def run
      @thread = Thread.new { run! }
      self
    end

    def then(&blk)
      fut = Future.new { blk.call(value) }
      fut.waiting_for = self

      case state
      when :pending
        callbacks << fut
      when :completed
        fut.run
      when :failed
        fut.fail_with(error)
      end

      fut
    end

    def await
      waiting_for && waiting_for.await

      unless thread
        run
      end

      thread.join
    end

    protected

    attr_accessor :waiting_for

    def complete_with(value)
      @value = value
      @state = :completed
      callbacks.each { |callback| callback.run }
    ensure
      freeze
    end

    def fail_with(error)
      @error = error
      @state = :failed
      callbacks.each { |callback| callback.fail_with(error) }
    ensure
      freeze
    end

    private

    attr_writer :state
    attr_reader :block, :thread

    def run!
      complete_with(block.call)
    rescue => e
      fail_with(e)
    end

    def callbacks
      @callbacks ||= []
    end

  end
end
