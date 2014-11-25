Browserify = require '../../..'

module.exports =
  extensions: [Browserify(files: "index.js", out: "build.js")]
