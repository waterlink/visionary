# Visionary

Simple futures implementation in ruby.

## Installation

Add this line to your application's Gemfile:

    gem 'visionary'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install visionary

## Usage

### Enabling `future` and `promise` helpers

```ruby
Visionary.setup!
```

### Futures

#### Deferring computation

Use `Kernel#future(&blk)` to define future and run it immediately:

```ruby
future { do_some_hard_work(some: :data) }
```

it is an alternative to:

```ruby
Visionary::Future.new { do_some_hard_work(some: :data) }.run
```

#### Checking the status of computation

You can check the status of computation inside of future by using `#state`:

```ruby
hard_work = future { do_some_hard_work(some: :data) }
hard_work.state     # => :pending
sleep(5.0)
hard_work.state     # => :completed
```

It can have 3 values: `:pending`, `:completed` and `:failed`.

#### Getting the result of computation

Once future has a state of `:completed`, it will hold the result of computation in `#value`:

```ruby
hard_work = future { do_some_hard_work(some: :data) }
do_something_else
hard_work.value     # => 42
```

When the future is completed it becomes `frozen`:

```ruby
hard_work.state     # => :completed
hard_work.frozen?   # => true
hard_work.run       # raises RuntimeError: can't modify frozen Visionary::Future
```

#### Explicitly awaiting for result with blocking

To block execution of until future is completed, you can use `#await` method on future:

```ruby
hard_work = future { do_some_hard_work(some: :data) }
hard_work.await
hard_work.state     # => :completed
```

#### Failed computations

```ruby
hard_work = future { raise RuntimeError }
hard_work.await
hard_work.state     # => :failed
hard_work.error     # => #<RuntimeError: RuntimeError>
```

#### Awaiting for result without blocking

To await for computation to complete and do something else after that without blocking use `#then` method on future:

```ruby
hard_work = future { do_some_hard_work(some: :data) }
easy_task = hard_work.then { |result| make_it_awesome(result) }
easy_task           # => #<Visionary::Future:0x0000012345678 @block=...>
do_something_else
easy_task.value     # => "awesome 42"
```

Under the hood it creates another future that will be run when current future is completed.

When previous future have failed, the failure will propagate to all waiting futures:

```ruby
hard_work = future { do_some_hard_work_and_loudly_fail! }
easy_task = hard_work.then { |result| make_it_awesome(result) }
easy_task.await
hard_work.state                         # => :failed
easy_task.state                         # => :failed
easy_task.error == hard_work.error      # => true
```

### Promises

#### Creating a promise

You could use `Kernel#promise` or `Visionary::Promise.new`. They are the same:

```ruby
p = promise                     # => #<Visionary::Promise:0x0000012345678>
p2 = Visionary::Promise.new     # => #<Visionary::Promise:0x0000012345679>
```

#### Obtaining a promised future

```ruby
p = promise
p.future    # => #<Visionary::Future:0x0000012345678 @block=nil, @state=:pending>
```

#### Completing a promised future

```ruby
def hard_working_task
  p = promise
  
  call_some_external_api(
    success_callback: -> { |value| p.complete(value) }
  )
  
  p
end
```

Promised future can be used as normal future:

```ruby
answer = hard_working_task

answer.state    # => :pending

do_something_else

answer.state    # => :completed
answer.value    # => 42
```

#### Failing a promised future

```ruby
def hard_working_task_often_fails
  p = promise
  
  call_some_faulty_external_api(
    success_callback: -> { ... }
    failure_callback: -> { |error| p.fail(error) }
  )
  
  p
end
```

#### Complex example what it can be used for

```ruby
def gather_data_from_multiple_sources(user_name)
  promises = {
    user: promise,
    friends: promise,
    likes: promise
  }
  
  user_call = future { api_call(:fetch_user, user_name) }
  user_call.then { |user| promises[:user].complete(user) }
  
  friends_call = user_call.then { |user| api_call(:fetch_friends, user) }
  friends_call.then { |friends| promises[:friends].complete(friends) }
  
  likes_call = user_call.then { |user| api_call(:fetch_likes, user) }
  likes_call.then { |likes| promises[:likes].complete(likes) }
  
  promises.inject({}) { |acc, kv| acc.merge kv[0] => kv[1].future }
end
```

## Contributing

1. Fork it ( https://github.com/waterlink/visionary/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
