path       = require 'path'
fs         = require 'fs'
_          = require 'lodash'
browserify = require 'browserify'
exorcist   = require 'exorcist'

module.exports = (opts) ->

  opts = _.defaults opts,
    files: 'js/main.js'
    opts: { extensions: ['.js', '.json', '.coffee']}
    minify: false
    sourceMap: false

  if not opts.out? then throw new Error("you must provide an 'out' path")

  opts.out = path.normalize(opts.out)
  opts.files = Array::concat(opts.files)

  class Browserify

    ###*
     * Sets up the custom category, maps all paths to the project root,
     * and initializes browserify and the coffee transform.
     * 
     * @param  {Function} @roots - Roots class instance
    ###

    constructor: (@roots) ->
      @category = 'browserify'
      @deps = []

      @files = opts.files.map((f) => path.join(@roots.root, f))
      @b = browserify(entries: @files, extensions: ['.js', '.json', '.coffee'])

      @b.transform('coffeeify')
      if opts.minify then @b.transform({ global: true }, 'uglifyify')

    ###*
     * Gets the dependency graph of required files so we can ignore them
     * from the compile process.
     * 
     * @return {Promise} promise for finishing getting the deps
    ###

    setup: ->
      deferred = W.defer()

      @b.deps()
        .on 'data', (res) =>
          @deps = @deps.concat(Object.keys(res.deps).map((key) => res.deps[key]))
        .on('end', deferred.resolve)

      return deferred.promise

    ###*
     * If the file was passed directly into browserify or it is a dependency
     * of one of the main files, extract from the roots pipeline because
     * browserify is going to handle the compilation.
    ###

    fs: ->
      extract: true
      detect: (f) =>
        _.contains(@files, f.path) or _.contains(@deps, f.path)

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

        out_path = path.join(@roots.config.output_path(), opts.out)
        stream = @b.bundle({ debug: opts.sourceMap })

        if opts.sourceMap
          map_path = out_path.replace(path.extname(out_path),'') + '.js.map'
          stream = stream.pipe(exorcist(map_path))

        stream.pipe(fs.createWriteStream(out_path))
          .on('error', deferred.reject)
          .on('close', deferred.resolve)

        return deferred.promise
