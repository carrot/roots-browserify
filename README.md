Roots Browserify
================

[![npm](http://img.shields.io/npm/v/roots-browserify.svg?style=flat)](https://badge.fury.io/js/roots-browserify) [![tests](http://img.shields.io/travis/carrot/roots-browserify/master.svg?style=flat)](https://travis-ci.org/carrot/roots-browserify) [![coverage](http://img.shields.io/coveralls/carrot/roots-browserify.svg?style=flat)](https://coveralls.io/r/carrot/roots-browserify) [![dependencies](http://img.shields.io/gemnasium/carrot/roots-browserify.svg?style=flat)](https://gemnasium.com/carrot/roots-browserify)

Roots browserify is an alternate javascript pipeline that uses commonjs and [browserify](http://browserify.org) to build and concatenate scripts.

> **Note:** This project is in early development, and versioning is a little different. [Read this](http://markup.im/#q4_cRZ1Q) for more details.

### Installation

- make sure you are in your roots project directory
- `npm install roots-browserify --save`
- modify your `app.coffee` file to include the extension, as such

  ```coffee
  browserify = require('roots-browserify')

  module.exports =
    extensions: [browserify(files: "assets/js/main.coffee", out: 'js/build.js')]
  ```

### Usage

This extension very directly uses browserify's javascript API under the hood. For basic usage, pass either a string with a file path or an array of file path strings as entry points for browserify, and an output path where all the concatenated scripts should be written, as shown in the example above.

### Options

##### files
String or array of strings pointing to one or more file paths which will serve as the base. See [browserify docs](https://github.com/substack/node-browserify#var-b--browserifyfiles-or-opts) for more info.

##### sourceMap
Generates an inline sourcemap, external if `minify` is `true`. Default is `false`.

##### minify
Minfifies the output. Default is `false`.

##### opts
Any additional options you'd like to be passed in to browserify. Again, documented [here](https://github.com/substack/node-browserify#var-b--browserifyfiles-or-opts). Default is `{ extensions: ['.js', '.json', '.coffee'] }`.

##### out
Where you want to output your built js file to in your `public` folder (or whatever you have set `output` to in the roots settings). There is no default. Recommended is `js/build.js`

##### transforms
If you'd like to add additional custom transforms, you can do it through this option. Pass either a transform function or an array of functions and they will be included in the pipeline. Default is `coffeeify` (add that string to your array if you want to keep coffeeify as well, otherwise it will be overridden).

### License & Contributing

- Details on the license [can be found here](LICENSE.md)
- Details on running tests and contributing [can be found here](contributing.md)
