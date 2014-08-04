Browserify = require '../../..'
data = require 'browserify-data'

module.exports =
  ignores: ["**/_*", "**/.DS_Store"]
  extensions: [Browserify(files: "index.js", out: "build.min.js", transforms: data)]
