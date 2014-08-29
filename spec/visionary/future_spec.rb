module Visionary
  RSpec.describe Future do

    describe "Kernel#future" do
      it "delegates to Future.new and chains with run" do
        fut = double("Future")
        block = -> { :i_am_a_block }

        allow(Future).to receive(:new).with(no_args) do |&blk|
          if blk == block
            fut
          else
            nil
          end
        end

        expect(fut).to receive(:run)

        future(&block)
      end
    end

    describe "#state" do
      it "is :pending when future is still computing the result" do
        fut = future { do_something; 42 }

        expect(fut.state).to eq(:pending)
      end

      it "is :failed when future failed to compute the result" do
        fut = future { raise RuntimeError }

        do_something

        expect(fut.state).to eq(:failed)
      end

      it "is :completed when future managed to compute the result" do
        fut = future { 42 }

        do_something

        expect(fut.state).to eq(:completed)
      end
    end

    describe "#frozen?" do
      it "is true when future is completed" do
        fut = future { 42 }

        do_something

        expect(fut.frozen?).to eq(true)
      end

      it "is true when future is failed" do
        fut = future { raise RuntimeError }

        do_something

        expect(fut.frozen?).to eq(true)
      end

      it "is false when future is pending" do
        fut = future { do_something; 42 }

        expect(fut.frozen?).to eq(false)
      end
    end

    describe "#value" do
      it "contains computation result when future is completed" do
        fut = future { 42 }

        do_something

        expect(fut.value).to eq(42)
      end

      it "contains nil when future is pending" do
        fut = future { do_something; 42 }

        expect(fut.value).to eq(nil)
      end

      it "contains nil when future is failed" do
        fut = future { raise RuntimeError }

        do_something

        expect(fut.value).to eq(nil)
      end
    end

    describe "#error" do
      it "contains error when future is failed" do
        error = RuntimeError.new(description: "Great runtime error")
        fut = future { raise error }

        do_something

        expect(fut.error).to be(error)
      end
    end

    describe "#then" do
      it "returns a future" do
        fut = future { do_something; 42 }

        fut2 = fut.then { do_something; :else }

        expect(fut2).to be_a(Future)
      end

      it "returns a new future" do
        fut = future { do_something; 42 }

        fut2 = fut.then { do_something; :else }

        expect(fut2).not_to be(fut)
      end

      it "eventually calculates something else" do
        fut = future { do_something; 42 }
        fut2 = fut.then { do_something; :else }

        4.times { do_something }

        expect(fut2.value).to eq(:else)
      end

      it "passes result to the provided block when completed" do
        fut = future { do_something; 42 }
        fut2 = fut.then { |answer| do_something; "answer is: #{answer}" }

        4.times { do_something }

        expect(fut2.value).to eq("answer is: 42")
      end

      it "raises the same error in a new future when failed" do
        error = RuntimeError.new(description: "Great runtime error")
        fut = future { do_something; raise error }
        fut2 = fut.then { |answer| do_something; "answer is: #{answer}" }

        2.times { do_something }

        expect(fut2.error).to eq(error)
      end

      it "does not start calculation of a new future until initial is completed" do
        fut = future { 2.times { do_something }; 42 }
        fut2 = fut.then { |answer| "answer is: #{answer}" }

        do_something

        expect(fut2.state).to eq(:pending)
      end

      context "when initial future is already completed" do
        it "immediately starts computation for a new future" do
          something = double("Something", notify: nil)
          fut = future { 42 }

          do_something

          fut2 = fut.then do |answer|
            something.notify(answer)
            2.times { do_something }
            answer + 3
          end

          do_something

          expect(something).to have_received(:notify).with(42)
        end
      end

      context "when initial future is already failed" do
        it "immediately fails a new future" do
          fut = future { raise RuntimeError }
          do_something

          fut2 = fut.then { |answer| do_something; answer + 3 }

          expect(fut2.state).to eq(:failed)
        end

      end
    end

    describe "#await" do
      it "awaits for computation to complete" do
        fut = future { do_something; 42 }

        fut.await

        expect(fut.state).to eq(:completed)
      end

      it "awaits for computation to fail" do
        fut = future { do_something; raise RuntimeError }

        fut.await

        expect(fut.state).to eq(:failed)
      end

      it "awaits for computation chain to complete" do
        fut = future { do_something; 42 }
        fut2 = fut.then { |answer| do_something; "Answer is: #{answer}" }
        fut3 = fut2.then { |report| do_something; "WTF? Why #{report.downcase}?" }

        fut3.await

        expect(fut3.value).to eq("WTF? Why answer is: 42?")
      end

      it "does not fails when awaits more than once" do
        fut = future { do_something; 42 }

        expect {
          fut.await
          fut.await
          fut.await
        }.not_to raise_error
      end
    end

    describe "#run" do
      it "runs future" do
        fut = Future.new { do_something; 42 }

        2.times { do_something }

        fut.run
        expect(fut.state).to eq(:pending)
      end

      it "cannot be run when it is already running" do
        fut = future { do_something; 42 }

        expect {
          fut.run
        }.to raise_error(RuntimeError)
      end
    end

    private

    def do_something
      sleep(0.01)
    end

  end
end
