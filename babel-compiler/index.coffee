#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 4/17/15 5:47 PM
#    Description: jade的编译器
_babel = null
_fs = require 'fs'

#标识这是一个silky插件
exports.silkyPlugin = true
#标识这是一个编译器的插件
exports.compiler = true

#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  registerReactCompiler 'babel.jsx', 'jsx', silky
  registerReactCompiler 'babel.es6', 'es6', silky

#注册一个react的编译器
registerReactCompiler = (compilerName, capture, silky)->
  #注册一个编译器
  silky.registerCompiler compilerName, capture: capture, (source, options, cb)->
    #避免加载太慢
    _babel = require 'babel' if not _babel
    utils = silky.utils

    babelOptions = {}
    source = utils.replaceExt source, capture
    return cb null, false if not _fs.existsSync source

    _babel.transformFile source, babelOptions, (err, result)->
      return cb err if err

      content = result.code
      if options.save and options.target
        target = utils.replaceExt options.target, '.js'
        utils.writeFile target, content

      cb null, content, target