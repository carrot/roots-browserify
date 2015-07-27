path       = require 'path'
fs         = require 'fs'
W          = require 'when'
_          = require 'lodash'
browserify = require 'browserify'
exorcist   = require 'exorcist'
through    = require 'through2'
uglifyify  = require 'uglifyify'
coffeeify  = require 'coffeeify'
mold       = require 'mold-source-map'

module.exports = (opts) ->

  opts = _.defaults opts,
    files: 'js/main.js'
    opts: { extensions: ['.js', '.json', '.coffee']}
    minify: false
    sourceMap: false
    transforms: [coffeeify]

  if not opts.out? then throw new Error("you must provide an 'out' path")

  opts.out = path.normalize(opts.out)
  opts.files = Array::concat(opts.files)
  opts.transforms = Array::concat(opts.transforms)
  _b = null

  class Browserify

    ###*
     * Sets up the custom category, maps all paths to the project root,
     * and initializes browserify and the coffee transform.
     *
     * @param  {Function} @roots - Roots class instance
    ###

    constructor: (@roots) ->
      @category = 'browserify'
      @cache = {}
      @pkg_cache = {}
      @changing_deps = {}

      @files = opts.files.map((f) => path.join(@roots.root, f))

      @b = browserify
        entries: @files
        extensions: ['.js', '.json', '.coffee']
        debug: opts.sourceMap
        cache: @cache
        packageCache: @pkg_cache

      @b.on 'package', (pkg) =>
        @pkg_cache[path.join(pkg.__dirname, 'package.json')] = pkg

      @b.transform(t) for t in opts.transforms
      if opts.minify then @b.transform(uglifyify, { global: true })

    ###*
     * Gets the dependency graph of required files so we can ignore them
     * from the compile process.
     *
     * @return {Promise} promise for finishing getting the deps
    ###

    setup: ->
      W.promise (resolve, reject) =>
        @b.pipeline.get('deps').push through.obj (row, enc, next) =>
          file = if row.expose then b._expose[row.id] else row.file

          @cache[file] =
            source: row.source
            deps: _.extend({}, row.deps)

          next(); resolve()

        @b.bundle()

    ###*
     * If the file was passed directly into browserify or it is a dependency
     * of one of the main files, extract from the roots pipeline because
     * browserify is going to handle the compilation.
    ###

    fs: ->
      extract: true
      detect: (f) =>
        _.contains(@files, f.path) or _.contains(Object.keys(@cache), f.path)

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

        changed = ctx.roots.file_changed
        if changed then invalidate.call(@, changed)

        stream = @b.bundle()

        if opts.sourceMap
          map_path = out_path.replace(path.extname(out_path),'') + '.js.map'

          ###
           * Convert output paths to be relative
           * to roots project instead of absolute paths
           * https://github.com/substack/node-browserify/issues/663
          ###
          stream = stream
          .pipe(mold.transformSourcesRelativeTo(@roots.root || ''))
          .pipe(exorcist(map_path))

        writer = fs.createWriteStream(out_path)

        stream.pipe(writer)
        stream.on('error', deferred.reject)
        writer.on('error', deferred.reject)
        writer.on('finish', deferred.resolve)

        return deferred.promise

    ###*
     * Given a file, invalidates this file and its dependants in the cache.
     *
     * @private
     * @param  {String} file - filename
    ###

    invalidate = (file) ->
      delete @cache[file]
      delete @pkg_cache[file]

      @changing_deps[file] = true
      @b.emit('update', Object.keys(@changing_deps))
