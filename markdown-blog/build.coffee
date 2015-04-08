#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/2/15 3:53 PM
#    Description: 构建项目

_path = require 'path'
_async = require 'async'
_fs = require 'fs-extra'

_storage = require './storage'
_utils = require './utils'
_rss = require './rss'

exports.execute = (data, cb)->
  tasks =
    home: buildHome
    index: buildIndex
    rss: buildRSS
    posts: buildPosts
    theme: buildTheme
    page: buildPage
    notFound: build404

  _async.series tasks, cb

#替换掉扩展名
replaceTargetExt = (target)->
  maps = coffee: 'js', hbs: 'html', less: 'css'
  target.replace /\.(coffee|hbs|less)$/i, (full, ext)-> ".#{maps[ext] || ext}"

#处理单个主题文件
buildThemeFile = (source, target, cb)->
  silky = _utils.global.silky
  fileType = silky.detectFileType source
  options =
    target: replaceTargetExt target
    save: true

  silky.compiler.execute fileType, source, options, (err, content)->
    #如果没有编译成功，则复制文件
    _fs.copySync source, target if content is false
    cb null

#处理主题的目录
buildThemeDir = (dir, cb)->
  list = _fs.readdirSync(dir)

  index = 0
  _async.whilst(
    -> index < list.length
    ((done)->
      file = _path.join dir, list[index++]
      relativePath = _path.relative _utils.global.themeDir, file

      #忽略template的目录以及css/module的目录
      return done null if /^(template|css\/module)$/i.test relativePath

      stat = _fs.statSync file
      return buildThemeDir file, done if stat.isDirectory()

      target = _path.join _utils.global.silky.options.output, relativePath
      buildThemeFile file, target, done
    ),
    cb
  )

###
  _fs.readdirSync(dir).forEach (filename)->
    file = _path.join dir, filename
    relativePath = _path.relative _utils.global.themeDir, file
    #忽略template的目录以及css/module的目录
    return if /^(template|css\/module)$/i.test relativePath

    stat = _fs.statSync file
    return buildThemeDir file, cb if stat.isDirectory()
    target = _path.join _utils.global.silky.options.output, relativePath
    buildThemeFile file, target, ->
###

#将主题编译到根目录
buildTheme = (cb)->
  buildThemeDir _utils.global.themeDir, cb

#生成首页
buildHome = (cb)-> buildIndexPage 1, true, cb

#构建索引页
buildIndexPage = (pageIndex, isHome, cb)->

  if isHome
    target = _utils.global.options.templateMap.home
    template = 'home'
  else
    target = pageIndex + _utils.global.options.extname
    template = 'index'

  _utils.compiler _utils.getIndexData(pageIndex), template, target, cb

#404页面
build404 = (cb)->
  _utils.compiler _utils.getBaseData(), '404', '404.html', cb

#构建page
buildPage = (cb)->
  pages = _storage.pages()
  index = 0
  _async.whilst(
    -> index < pages.length
    (done)-> buildSinglePost(pages[index++].url, done)
    cb
  )
#生成索引页
buildIndex = (cb)->
  index = 1
  total = _storage.postCount()
  pageCount = Math.ceil(total / _utils.global.options.pageSize)

  _async.whilst(
    (->index <= pageCount),
    (
      (done)-> buildIndexPage index++, false, done
    ), (err)-> cb null
  )


#生成rss
buildRSS = (cb)->
  rssFile = _path.join _utils.global.silky.options.output, _utils.global.options.templateMap.rss
  content = _rss.generator()
  _fs.outputFileSync rssFile, content
  cb null

#生成文章页，包括
buildSinglePost = (url, cb)->
  pluginData = _utils.getPostData url
  template = if pluginData.post.type is 'page' then 'page' else 'post'
  target = pluginData.post.url
  _utils.compiler pluginData, template, target, cb

#生成文章页
buildPosts = (cb)->
  index = 0
  post = null
  _async.whilst(
    (->
      posts = _storage.findPost(start: index, end: ++index)
      post = posts[0]
      posts.length > 0
    )
    (done)-> buildSinglePost post.url, done
    (err)-> cb null
  )