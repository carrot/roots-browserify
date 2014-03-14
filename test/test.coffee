path   = require 'path'
fs     = require 'fs'
should = require 'should'
glob   = require 'glob'
rimraf = require 'rimraf'
Roots  = require 'roots'
W      = require 'when'
nodefn = require 'when/node/function'
_path  = path.join(__dirname, 'fixtures')
run = require('child_process').exec

# setup, teardown, and utils

should.file_exist = (path) ->
  fs.existsSync(path).should.be.ok

should.have_content = (path) ->
  fs.readFileSync(path).length.should.be.above(1)

should.contain = (path, content) ->
  fs.readFileSync(path, 'utf8').indexOf(content).should.not.equal(-1)

compile_fixture = (fixture_name, done) ->
  @path = path.join(_path, fixture_name)
  @public = path.join(@path, 'public')
  project = new Roots(@path)
  project.compile().on('error', done).on('done', done)

before (done) ->
  tasks = []
  for d in glob.sync("#{_path}/*/package.json")
    p = path.dirname(d)
    if fs.existsSync(path.join(p, 'node_modules')) then continue
    console.log "installing deps for #{d}"
    tasks.push nodefn.call(run, "cd #{p}; npm install")
  W.all(tasks, -> done())

after ->
  rimraf.sync(public_dir) for public_dir in glob.sync('test/fixtures/**/public')

# tests

describe 'basic', ->

  before (done) ->
    compile_fixture.call(@, 'basic', done)
    @public = path.join(_path, 'basic/public')

  it 'should compile output', ->
    build = path.join(@public, 'build.min.js')

    should.file_exist(build)
    should.contain(build, "var doge = require('./doge');")
    should.contain(build, "module.exports = 'wow'")

describe 'minify', ->

  before (done) ->
    compile_fixture.call(@, 'minify', done)
    @public = path.join(_path, 'minify/public')

  it 'should compile and minify output', ->
    build = path.join(@public, 'build.min.js')

    should.file_exist(build)
    should.contain(build, 'var doge=require("./doge");')
    should.contain(build, 'module.exports="wow"')

describe 'sourcemap', ->

  before (done) ->
    compile_fixture.call(@, 'sourcemap', done)
    @public = path.join(_path, 'sourcemap/public')

  it 'should compile and provide sourcemap', ->
    build = path.join(@public, 'build.min.js')

    should.file_exist(build)
    should.contain(build, "//# sourceMappingURL=data:application/json;base64")
    should.contain(build, "var doge = require('./doge');")
    should.contain(build, "module.exports = 'wow'")

describe 'minify-sourcemap', ->

  before (done) ->
    compile_fixture.call(@, 'minify-sourcemap', done)
    @public = path.join(_path, 'minify-sourcemap/public')

  it 'should compile, minify, and provide sourcemap', ->
    build = path.join(@public, 'build.min.js')
    map = path.join(@public, 'build.min.map.json')

    should.file_exist(build)
    should.contain(build, 'var doge=require("./doge");')
    should.contain(build, 'module.exports="wow"')
    should.contain(build, '//# sourceMappingURL=/build.min.map.json')
    should.file_exist(map)
    should.have_content(map)

describe 'coffeescript', ->

  before (done) ->
    compile_fixture.call(@, 'coffeescript', done)
    @out = path.join(_path, 'coffeescript/public/build.js')

  it 'should compile coffeescript files', ->
    should.contain(@out, "doge = require('./doge');")
    should.contain(@out, "module.exports = 'wow';")

# describe 'coffeescript-minify'
# does not work because of a bug in the minifier

# describe 'coffeescript-sourcemap'
# does not work because of a bug in the minifier

# describe 'coffeescript-minify-sourcemap'
# does not work because of a bug in the minifier
