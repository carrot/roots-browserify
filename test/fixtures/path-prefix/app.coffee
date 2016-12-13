browserify = require '../../..'

module.exports =
  ignores: ["**/_*", "**/.DS_Store"]
  extensions: [browserify(files: "index.coffee", out: "build.js")]
