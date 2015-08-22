# Pakyow Console

Console is a web-based development and management tool for your Pakyow app.

# Getting Started

Add Console to your `Gemfile`:

```ruby
gem 'pakyow-console', git: 'git@github.com:pakyow/console.git'
```

Run `bundle install` and you're ready to go. Start your Pakyow app and navigate
to `/console` in a web browser. You'll be taken through a setup process.

# Console Data

Console can be used to manage your app's data. Just tell Console about a data
type and it will bootstrap a management interface for you.

Let's say we're building a blog and we want to manage our blog posts. First,
create a `app/lib/schema.rb` file (this is best practice, but really data type
definitions can live anywhere in your app). Now, add the following code:

```ruby
Pakyow::Console.data :post, icon: 'newspaper-o' do
  self.model = :Post

  attribute :title, :string
  attribute :description, :html
end
```

The first argument (`:post`) is the name of our datatype. The `icon` argument
defines a Font Awesome class for Console to use when representing this datatype.

Within the block, we define our model class. This is expected to be a Sequel
model. Console will respect all validations and hooks defined on your model.
Next, we define the attributes we want Console to manage. Here, an interface
will be built for us to manage the `title` and `description` of our posts.

The second argument to `attribute` defines the editor to use. For `title`, we
want to use a string editor, or a text box. The `description` attribute will be
managed via a WYSIWYG editor.

## Editor Types

Console ships with editors for the following types:

**String**

A `input[type=text]` field.

**Text**

A `textarea` field.

**Enum**

A `select` field. Define options like this:

```ruby
attribute :type, :enum, values: [['', ''], [:foo, 'foo'], [:bar, 'bar']]
```

**Boolean**

A `checkbox` field.

**Monetary**

A `String` field, with a dollar sign.

**File**

A `input[type=file]` field.

**Percentage**

A `String` field, with a percent sign.

**HTML**

A WYSIWYG field (via Redactor).

**Sensitive**

A `input[type=password]` field.

## Type Formatters

A formatter formats data of a particular type when rendering it in a Console
view. Console ships with formatters for the following types:

**Percentage**

Percent values are stored as floating point (e.g. 0.50 rather than 50%). This
formatter will render the value as a percentage.

## Type Processors

A processor will process form data and santitize before handing it to the model
to be saved. Console ships with processors for the following types:

**Boolean**

Converts form values (e.g. `0` or `1`) to a boolean value.

**File**

Saves the file in Console's file store.

**Float**

Converts string values to floating point.

**Percentage**

Converts a percentage value to a floating point value.

# Console Data Views

It's possible to override the default views for Console's data management
interface (currently, only the `list` view). Just create a view in your app's
`views` folder, following this naming convention:

```
console/data/{type}/index.html
```

# Custom Editors / Formatters / Processors

It's possible to extend Console with custom Editors, Formatters, and Processors.

Take a look at the ones defined in the Console source code for examples.

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
