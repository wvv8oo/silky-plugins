#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/29/15 11:07 AM
#    Description: markdown的插件

_path = require 'path'

_utils = require './utils'
_rss = require './rss'
_router = require './router'
_build = require './build'


#标识这是一个silky插件
exports.silkyPlugin = true

#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  _utils.registerPlugin silky, pluginOptions

  #注册一个markdown的helper
  silky.registerHandlebarsHelper 'plugin_markdown', _utils.markdownHelper
  #注册一个根据url获取文章内容的helper
  silky.registerHandlebarsHelper 'plugin_content', _utils.contentHelper
  #初始化的时候，加载markdown
  silky.registerHook 'route:initial', {}, -> _utils.loadMarkdown()
  silky.registerHook 'build:initial', {}, -> _utils.loadMarkdown()
  silky.registerHook 'build:willProcess', {}, (data)->
    #忽略数据目录下所有的markdown文件
    data.ignore = _utils.pathIsDataDirectory(data.source) and /md|markdown$/i.test data.source

  #全部构建完成
  silky.registerHook 'build:didMake', {async: true}, (data, done)->
    _build.execute data, done


  #接管路由
  silky.registerHook 'route:didRequest', {}, (data, done)-> _router.didRequest(data, done)


