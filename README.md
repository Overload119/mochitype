# Mochitype

For Ruby on Rails apps that have a Typescript frontend, your left with few options to ensure your Typescript types are correct.

You either manually create Typescript interfaces or manually write Zod for runtime checks.

Mochitype turns your `T::Struct` classes into Zod types, allowing your frontend and backend to share a common type definition. This gives you:

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
Mochitype.start_watcher!
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

## Using Mochitype::View for Rendering

The `Mochitype::View` module provides a simple way to make your `T::Struct` classes renderable in Rails controllers. When you include this module, your struct gains two methods:

- `render_in(view_context)` - Serializes the struct to JSON
- `format` - Returns `:json` to indicate the response format

### Basic Usage

Include `Mochitype::View` in any `T::Struct` class:

```ruby
class UserResponse < T::Struct
  include Mochitype::View

  const :id, Integer
  const :name, String
  const :email, String
end
```

Then use it directly in your controllers:

```ruby
class UsersController < ApplicationController
  def show
    user = User.find(params[:id])
    response = UserResponse.new(id: user.id, name: user.name, email: user.email)

    render response
  end
end
```

### Advanced Example with Nested Structs

```ruby
module API
  module Users
    class IndexResponse < T::Struct
      include Mochitype::View

      class UserSummary < T::Struct
        const :id, Integer
        const :name, String
        const :avatar_url, T.nilable(String)
      end

      const :users, T::Array[UserSummary]
      const :total_count, Integer
      const :page, Integer

      sig { params(users: T::Array[User], page: Integer).returns(IndexResponse) }
      def self.from_users(users:, page:)
        new(
          users:
            users.map do |user|
              UserSummary.new(id: user.id, name: user.name, avatar_url: user.avatar_url)
            end,
          total_count: users.size,
          page: page,
        )
      end
    end
  end
end

# In your controller:
class API::UsersController < ApplicationController
  def index
    users = User.page(params[:page])
    render API::Users::IndexResponse.from_users(users: users, page: params[:page].to_i)
  end
end
```

### Benefits

1. **Type Safety**: Your responses are type-checked by Sorbet at the Ruby level
2. **Automatic TS Generation**: The corresponding TypeScript types are automatically generated
3. **Clean Controllers**: Separates response structure from controller logic
4. **Reusable**: Response classes can be shared across multiple endpoints

### What Gets Generated

For the examples above, Mochitype will automatically generate TypeScript types like:

```typescript
// __generated__/mochitypes/user_response.ts
export const UserResponse = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string(),
});

export type TUserResponse = z.infer<typeof UserResponse>;
```

This keeps your frontend types perfectly in sync with your backend responses!

## Limitations

- Currently only works with T::Structs, T::Enum, and standard Ruby types like String, Integer, etc. If your struct has a field that's a custom class, it will be marked as `unknown`
- Since we're using the Prism parser, it requires Ruby 3.3.5+
- It does not de-dupe types across files. For example, if you have MyStruct and reference MyOtherStruct, both of those Typescript files will contain TS on MyOtherStruct.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mochitype.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
