module Visionary
  RSpec.describe Promise do

    describe "Kernel#promise" do
      it "creates new promise" do
        p = double("Promise")

        allow(Promise).to receive(:new) { p }

        expect(promise).to be(p)
      end
    end

    describe "#future" do
      it "returns associated future" do
        expect(promise.future).to be_a(Future)
      end

      it "returns the exact future all the times" do
        p = promise
        expect(p.future).to be(p.future)
      end

      it "returns pending future" do
        expect(promise.future.state).to eq(:pending)
      end
    end

    describe "#complete" do
      it "completes future" do
        p = promise
        expect { p.complete(42) }
          .to change { p.future.state }
          .from(:pending)
          .to(:completed)
      end

      it "stores passed value as a value in future" do
        p = promise
        p.complete(42)
        expect(p.future.value).to eq(42)
      end

      it "becomes frozen" do
        p = promise
        p.complete(42)
        expect(p.frozen?).to eq(true)
      end
    end

    describe "#fail" do
      it "failes future" do
        p = promise
        expect { p.fail(RuntimeError.new) }
          .to change { p.future.state }
          .from(:pending)
          .to(:failed)
      end

      it "stores passed error as an error in future" do
        p = promise
        error = RuntimeError.new("Crazy description")
        p.fail(error)
        expect(p.future.error).to be(error)
      end

      it "becomes frozen" do
        p = promise
        p.fail(RuntimeError.new)
        expect(p.frozen?).to eq(true)
      end
    end

  end
end
