#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/2/15 3:58 PM
#    Description:

_ = require 'lodash'
_marked = require 'marked'
_path = require 'path'
_fs = require 'fs-extra'
_urlRelative = require 'url-relative'

_storage = require './storage'

_global = {}

exports.global = _global

#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  _global.options = pluginOptions
  _global.silky = silky

  #默认的插件设置
  defaultOptions =
    #页大小
    pageSize: 10
    #基本的目录
    basePath: '/'
    #默认主题
    theme: 'hyde'
    #post/page的扩展名
    extname: '.html'
    #识别markdown的日期格式
    dateFormatter: 'YYYY-MM-dd hh:mm'
    #模板映射
    templateMap:
      home: '/index.html'
      post: '/post'
      page: '/page'
      tag: '/tag'
      rss: '/rss.xml'
    #rss的配置
    rss:
      #输出rss的限制
      limit: 20
      #全文输入
      full: true
    #博客的基本配置
    blog:
      title: 'My Blog'
      description: 'More...'
      host: '/'
      feed: 'rss.xml'
      author: 'Silky'

  #覆盖掉默认的配置
  _global.options = _.merge defaultOptions, pluginOptions

  #合并模板映射
#  mergeTemplateMap()
  #设置主题
  setThemeDirectory()

#获取某个url相对于basePath的相对路径
exports.getRelativePath = (url)->
  url = _global.options.basePath + url
  return '' if url is _global.options.basePath
  relativePath = _urlRelative(url, _global.options.basePath)
  relativePath = '' if relativePath is '..'
  relativePath
#  relativePath += "/" if relativePath

#响应索引页的数据
exports.getIndexData = (pageIndex = 1)->
  pageSize = _global.options.pageSize
  cond = start: pageSize * (pageIndex - 1)
  cond.end = cond.start + pageSize

  result = {
    pagination: getPagination(pageIndex, pageSize, _storage.postCount())
    pages: _storage.pages()
    blog: _global.options.blog
    posts: _storage.findPost cond
    nav: {}
    options: _global.options
    env: relativePath: exports.getRelativePath('/')
  }

  result.nav.previous = pageIndex - 1 if pageIndex > 1
  result.nav.next = pageIndex + 1 if pageIndex < result.pagination.pageCount

  result

#获取基本的数据，一般用于404
exports.getBaseData = ->
  return {
    blog: _global.options.blog
    options: _global.options
    pages: _storage.pages()
    blog: _global.options.blog
  }

#获取单个文章的内容
exports.getPostData = (url)->
  return {
    pages: _storage.pages()
    blog: _global.options.blog
    post: _storage.onePost url
    options: _global.options
    env: relativePath: exports.getRelativePath(url)
  }

#获取所有markdown到缓存
exports.loadMarkdown = ->
  dataDir = _path.resolve(_global.silky.options.workbench, _global.options.dataDir || './')
  _storage.initial dataDir

#转换markdown
exports.markdownHelper = (content, options)->
  _marked(content || '')

#根据url获取文章的内容
exports.contentHelper = (url, options)->
  content = _storage.getPostContent url
  exports.markdownHelper content, options

#获取post/page的url
exports.getPostUrl = (type, link)->
  type = _global.options.templateMap[type]
  return link if not type

  url = _path.relative _global.options.basePath, _path.join(type, link)
  extname = _global.options.extname

  url += extname if not exports.endWith(url, extname)
  url

#判断是否以某个字符结尾
exports.endWith = (text, endStr)->
  text = text.toLowerCase()
  endStr = endStr.toLowerCase()
  lastIndex = text.lastIndexOf(endStr)
  return false if lastIndex is -1

  text.substr(lastIndex, endStr.length) is endStr

#获取分页数据
getPagination = (pageIndex, pageSize, recordTotal)->
  maxPage = 5
  #计算分页
  page =
    recordTotal: recordTotal
    pageIndex: pageIndex
    pageSize: pageSize
    items: []

  page.pageCount = Math.ceil(page.recordTotal / pageSize)
  start = Math.max(1, page.pageIndex - maxPage)
  end = Math.min(start + maxPage * 2, page.pageCount)

  return page if start is end or end is 0

  for index in [start..end]
    page.items.push
      index: index
      current: index is page.pageIndex
  page

#获取主题的目录
setThemeDirectory = ->
  theme = _global.options.theme || 'hyde'
  _global.themeDir = _path.join _global.silky.options.workbench, theme, 'template'
  #工作目录下没有主题，则考虑系统默认主题
  if not _fs.existsSync(_global.themeDir)
    _global.themeDir = _path.join __dirname, 'themes', theme

    #还是没有，则认为是配置错误
    if not _fs.existsSync(_global.themeDir)
      console.log "主题无法找到 -> #{_global.themeDir}".red
      process.exit 1

#合并模板映射
mergeTemplateMap = ()->
  #默认映射
  defaultTemplateMap =
    #索引页_templateMap
    index: '/index.html'
    #文章页
    post: '/post'
    #page
    page: '/page'
    #标签
    tag: '/tag'
    #rss
    rss: '/rss.xml'

  _global.templateMap = _.extend defaultTemplateMap, _global.options.templateMap

#获取模板的文件全路径
exports.getTemplateFile = (type)->
  _path.join _global.themeDir, 'template', type + '.hbs'

#编译主题中的模板
exports.compiler = (pluginData, template, target, cb )->
  templateFile = exports.getTemplateFile(template)
  options =
    save: true
    pluginData: pluginData
    target: _path.join _global.silky.options.output, target

  _global.silky.compiler 'hbs', templateFile, options, cb

#检查目录是否为数据目录
exports.pathIsDataDirectory = (path)->
  dataDir = _global.options.dataDir || './'
  basePath = _path.resolve _global.silky.options.workbench, dataDir

  path.indexOf(basePath) is 0