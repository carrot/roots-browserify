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
    opts: { extensions: ['.js', '.json', '.coffee']}
    minify: false
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

      @b = browserify({ extensions: ['.js', '.json', '.coffee'] })

      if Array.isArray(opts.files)
        opts.files.forEach((f) => @b.add(path.join(@roots.root, f)))
      else
        @b.add(path.join(@roots.root, opts.files))

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

        output_path = path.join(@roots.config.output_path(), opts.out)
        sourcemap_path = output_path.replace(path.extname(output_path),'') + '.map.json'
        sourcemap_path_relative = sourcemap_path.replace(@roots.config.output_path(), '')

        stream = @b.bundle({ debug: opts.minify || opts.sourceMap })
        map = if opts.sourceMap then sourcemap_path_relative else false

        if opts.minify
          stream.pipe minifyify { map: map }, (err, src, map) ->
            if err then return deferred.reject(err)
            fs.writeFileSync(output_path, src);
            if opts.sourceMap then fs.writeFileSync(sourcemap_path, map);
            deferred.resolve()
        else
          stream.pipe(fs.createWriteStream(output_path))
            .on('error', deferred.reject)
            .on('close', deferred.resolve)

        return deferred.promise
