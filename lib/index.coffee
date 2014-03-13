path       = require 'path'
fs         = require 'fs'
W          = require 'when'
_          = require 'lodash'
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
minifyify  = require('minifyify')

module.exports = (opts) ->

  opts = _.defaults opts,
    files: 'js/main.js'
    opts: { extensions: '.coffee'}
    minify: true
    sourceMap: false

  if not opts.out? then throw new Error("you must provide an 'out' path")

  class Browserify

    ###*
     * Sets up the custom category, maps all paths to the project root,
     * and initializes browserify and the coffee transform.
     * 
     * @param  {Function} @roots - Roots class instance
    ###

    constructor: (@roots) ->
      @category = 'browserify'

      files = if Array.isArray(files)
        opts.files.map((f) -> path.join(@roots.root, f))
      else
        path.join(@roots.root, opts.files)

      @b = browserify(files, { extensions: ['.js', '.json', '.coffee'] })
      @b.transform('coffeeify')

    ###*
     * Selects all js and/or coffee files for processing and extracts them
     * from the pipeline. It *should* be using browserify.deps() to figure
     * out only the required files, but that seems to be bugged out at the
     * moment, so for now it pulls all js files.
    ###

    fs: ->
      extract: true
      detect: (f) ->
        ext = path.extname(f.relative)
        ext is '.coffee' or ext is '.js'

    ###*
     * Zero out the contents so nothing is compiled and don't write the file.
     * Browserify will take care of this instead.
    ###

    compile_hooks: ->
      before_file: (ctx) -> ctx.content = ''
      write: -> false

    ###*
     * Run browserify logic.
     *
     * @todo if output folder doesnt exist, create it?
     * @todo wrap output with UMD?
    ###

    category_hooks: ->
      after: (ctx) =>
        deferred = W.defer()

        out = fs.createWriteStream(path.join(@roots.config.output_path(), opts.out))

        stream = @b.bundle({ debug: opts.sourceMap })

        # if opts.minify then stream.pipe(minifyify())
        # - unfortunately, minification isn't going to work here yet
        # - https://github.com/ben-ng/minifyify/issues/27
        
        stream.pipe(out)
          .on('error', deferred.reject)
          .on('close', deferred.resolve)

        return deferred.promise
