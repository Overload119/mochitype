# Development

The easiest way is to `cd examples/example-app` and run `rails s`
Edit code, and run the example app to make sure it still works and is generating the right types.

Another easy way to test is to add a Ruby struct file to `spec/test-data` and run `bundle exec rspec`
This will error at first and the error should be easy to resolve.
