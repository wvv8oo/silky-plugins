#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 4/17/15 5:47 PM
#    Description: jade的编译器
_jade = null
_ = require 'lodash'

#标识这是一个silky插件
exports.silkyPlugin = true
#标识这是一个编译器的插件
exports.compiler = true

#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  #编译器选项
  compilerOptions =
    #将要捕获的扩展名，可以是数组
    capture: 'jade'
    #编译后的扩展名
    target: 'html'

  #注册一个编译器
  silky.registerCompiler 'jade', compilerOptions, (source, options, cb)->
    _jade = require 'jade' if not _jade
    utils = silky.utils

    jadeOptions =
      filename: source
      pretty: true

    _.extend jadeOptions, silky.data.json

    #读取文件
    content = utils.readFile source
    content = _jade.render content, jadeOptions


    if options.save and options.target
      target = utils.replaceExt options.target, '.html'
      utils.writeFile target, content

    cb null, content, target