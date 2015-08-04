_ = require 'lodash'
_fs = require 'fs-extra'
_url = require 'url'
_path = require 'path'

_override = require './override'
_merge = require './merge'

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
#在build和路由启动的时候，加入系统变量
  silky.registerHook 'route:initial', -> _override.convert silky, pluginOptions
  silky.registerHook 'build:initial', -> _override.convert silky, pluginOptions

  #将要响应的时候，
  silky.registerHook 'route:willResponse', {}, (data, done)->
    url = _url.parse data.request.url
    #非html不用处理
    return if not /\.html$/.test url.pathname

    #合并honey，但不合并css
    data.content = _merge.execute silky, data, data.content, false
    #替换掉所有的component/css
    data.content = data.content.replace /type=.component\/css./ig, 'type="text/css"'

  #编译后，处理honey和css
  silky.registerHook 'build:didCompile', {async: true}, (data, done)->
    return done null if not /\.html$/.test data.target

    #读取文件，准备交给merge处理
    content = _fs.readFileSync data.target, 'utf-8'
    content = _merge.execute silky, data, content, true
    silky.utils.writeFile data.target, content
    done null

  #构建完成后，合并global css
  silky.registerHook 'build:didMake', (data, done)->
    _merge.mergeGlobalCSS silky, data