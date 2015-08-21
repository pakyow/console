# Pakyow Console

Console is a web-based development and management tool for your Pakyow app.

# Getting Started

Add Console to your `Gemfile`:

```ruby
gem 'pakyow-console', git: 'git@github.com:pakyow/console.git'
```

Run `bundle install` and you're ready to go. Start your Pakyow app and navigate
to `/console` in a web browser. You'll be taken through a setup process.

# Custom User Model

By default, Console will use its built-in `User` model. This means users for
your app will be completely separate from Console. If you wish to use the same
model for Console and your app, simply set this config option in the `global`
configure block in `app/setup.rb`:

```ruby
console.models[:user] = 'User'
```

Your `User` model *must* subclass `Sequel::Model`. Console expects your model to
have the following fields:

- name:String
- email:String
- username:String
- crypted_password:String
- active:Boolean

You must implement an `authenticate` class method that authenticates the user
with a `login` and `password`. Return `true` on success and `false` on failure.

Console also expects your model to implement the following instance methods:

`password=`

You should encrypt your password in the setter; we recommend bcrypt.

`consolify`

Console calls this method when granting access to Console, leaving you free to
implement a role system however you'd like to.

`console?`

Returns `true` if the user has permission to access Console.
