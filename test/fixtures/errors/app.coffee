Browserify = require '../../..'

module.exports =
  ignores: ["**/_*", "**/.DS_Store"]
  extensions: [Browserify(files: "index.js")]
