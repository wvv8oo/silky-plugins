#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 4/17/15 5:47 PM
#    Description: jade的编译器
_jade = require 'jade'
_ = require 'lodash'

#标识这是一个silky插件
exports.silkyPlugin = true
#标识这是一个编译器的插件
exports.compiler = true

#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  #注册一个编译器
  silky.registerCompiler 'jade', (source, options, cb)->
    jadeOptions =
      filename: source
      pretty: true

    _.extend jadeOptions, silky.data.json

    #读取文件
    content = silky.utils.readFile source
    content = _jade.render content, jadeOptions
    silky.utils.writeFile source if options.save and options.output
    cb null, content