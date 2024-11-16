> [!WARNING]
> WIP! You cannot use this gem yet. 

# Mochitype

For Ruby on Rails apps that have a Typescript frontend, there's no good way to make sure that the backend is sending a payload that the frontend understands.

You either manually create Typescript interfaces or manually write Zod for runtime checks.

Mochitype turns your T::Struct classes into Zod types, allowing your frontend and backend to share a common type definition. This gives you:

- Typescript interfaces in sync with the backend with Zod infer.
- Runtime type checking with Zod.
- A typed interface using Sorbet for building your JSON payload.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mochitype'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install mochitype

## Usage

1. Configure the

```
Mochitype.configure do |config|
  config.watch_path = "app/mochitypes"
  config.output_path = "app/javascript/__generated__/mochitypes"
end
```

2. When your Rails app starts in development, it'll watch all files in `watch_path` - each time a file is added, modified, or deleted, it'll update the corresponding TypeScript file in `output_path`.

3. Since your Ruby classes are T::Structs, you can also DRY up your rendering logic.

```ruby
# before
class UsersController < ApplicationController
  def index
    @users = User.all
    render json: @users
  end
end

# after
class UsersController < ApplicationController
  def index
    # has access to helpers
    render Mochiviews::Users::Index.render(
      users: User.all,
    )
  end
end

class Mochiviews::Users::Index < T::Struct
  class User < T::Struct
    const :id, Integer
    const :name, String
  end

  const :users, T::Array[Mochiviews::Users::Index::User]

  sig { params(users: T::Array[User]).returns(Mochiviews::Users::Index) }
  def self.render(users:)
    Mochiviews::Users::Index.new(
        users: users.map do |user|
          User.new(
            id: user.id,
            name: user.name,
          )
        end
    )
  end
end

# Mochiviews::Users::Index is automatically converted to Zod
# app/javascript/__generated__/mochitypes/users/index.ts
export const UsersIndexSchema = z.object({
  users: z.array(z.object({
    id: z.number(),
    name: z.string(),
  })),
});

export type UsersIndex = z.infer<typeof UsersIndexSchema>;
```

Now if you change UsersController#index to return something different, it'll update the corresponding TypeScript file. Your backend and frontend are always in sync!

## Development

The easiest way is to `cd examples/example-app` and run `rails s`
Edit code, and run the example app to make sure it still works and is generating the right types.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mochitype.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
