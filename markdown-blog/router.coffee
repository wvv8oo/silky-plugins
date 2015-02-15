#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/2/15 4:07 PM
#    Description: 路由处理
_path = require 'path'
_url = require 'url'
_fs = require 'fs-extra'

_utils = require './utils'
_rss = require './rss'
_storage = require './storage'

#处理路由
exports.didRequest = (data, done)->
  #不是配置的bashPath开头的，则不处理
  url = data.route.url
  basePath = _utils.global.options.basePath || '/'
  return done null if url.indexOf(basePath) isnt 0

  relativeUrl = url.replace basePath, ''
  #首页
  if not relativeUrl or /^\index\.html$/i.test relativeUrl
    data.route.type = 'html'
    relativeUrl  = '/'

  return done null if rssHandler data, relativeUrl

  #检查是否theme内的静态文件
  if data.route.type is 'html'
    templateHandler data, relativeUrl
    return done null

  #处理其它静态文件
  staticHandler data, relativeUrl, done

#处理rss
rssHandler = (data, relativeUrl)->
  rssPath = _utils.global.options.templateMap.rss
  return false if relativeUrl isnt rssPath

  data.stop = true
  res = data.response
  res.setHeader 'content-type', 'application/rss+xml'
  res.end _rss.generator()

#处理404的错误
notFoundHandler = (data)->
  data.route.realpath = _utils.getTemplateFile '404'
  data.route.type = data.route.compiler = 'hbs'
  data.route.mime = 'text/html'
  data.pluginData = _utils.getBaseData()

#响应静态文件
staticHandler = (data, relativeUrl, cb)->
  data.route.realpath = _path.join _utils.global.themeDir, relativeUrl
  #文件存在，则直接返回
  return cb null if _fs.existsSync(data.route.realpath)

  compiler = _utils.global.silky.compiler

  #取得真实的源文件路径
  realpath = compiler.sourceFile data.route.compiler, data.route.realpath

  if realpath
    data.route.realpath = realpath
  else
    #如果没有找到匹配的源文件，则按404处理
    notFoundHandler data

  return cb null


#响应html，处理模板
templateHandler = (data, relativeUrl)->
  maps = _utils.global.options.templateMap

  #首页
  if relativeUrl is '/' or relativeUrl is maps.home
    data.route.compiler = 'hbs'
    data.pluginData = _utils.getIndexData()
    data.route.realpath = _utils.getTemplateFile('home')
    data.route.mime = 'text/html'
    return true

  #匹配到文章页
  if post = _storage.onePost(relativeUrl)
    data.route.compiler = 'hbs'
    data.pluginData = _utils.getPostData(relativeUrl)
    data.route.realpath = _utils.getTemplateFile(post.type)
    data.route.type = 'html'
    return true

  #匹配索引页
  pattern = "^(\\d+)#{_utils.global.options.extname.replace('.', '\\.')}$"
  reg = new RegExp(pattern, 'i')
  indexTemplateHandler(data, parseInt(match[1])) if match = relativeUrl.match(reg)

#响应索引页的模板
indexTemplateHandler = (data, pageIndex = 1)->
  data.route.compiler = 'hbs'
  data.pluginData = _utils.getIndexData(pageIndex)
  data.route.realpath = _utils.getTemplateFile('index')
  data.route.mime = 'text/html'

#是否匹配模板
isMatchTemplate = (rule, url)->
  return url.indexOf(rule) is 0 if typeof rule is 'string'

#获取模板类型
getTemplateType = (relativeUrl)->
  #首页作特别处理
  return 'index' if relativeUrl is '/'
  for key, value of _utils.global.templateMap
    return key if isMatchTemplate(value, relativeUrl)