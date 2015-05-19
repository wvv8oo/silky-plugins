_cheerio = require 'cheerio'
_ = require 'lodash'
_fs = require 'fs-extra'
_url = require 'url'
_path = require 'path'
#_uglify = require 'uglify-js'

##压缩内联的js
#压缩JS后期会交给Silky，不需要在Honey中处理
#compressInternalJavascript = (file, content)->
#  try
#    content = _uglify.minify(content, fromString: true).code
#  catch e
#    console.log "压缩HTML中的JS代码出错，详细错误如下：".red
#    console.log "错误的文件 -> #{file}".red
#    console.log content
#    console.log e
#    process.exit 0
#
#  content

#合并honey中的依赖
combineHoney = (content)->
  $ = _cheerio.load content
  deps = []
  scripts = []
  $('script[honey]').each ()->
    $this = $(this)
    #合并依赖
    deps = _.union(deps,$this.attr('honey').split(','))
    #临时保存脚本
    scripts.push $this.html()
    #删除这个script标签
    $this.remove()

  #没有找到标签
  return content if scripts.length is 0

  #处理合并项
  html = "\thoney.go(\"#{_.compact(deps).join(',')}\", function() {\n"
  #将所有的代码都封装到闭包中运行
  for script in scripts
    #不处理空的script
    html += "\t(function(){\n#{script}\n\t}).call(this);\n\n"
  html += '\n\t});'

  #压缩内联的js
#  html = compressInternalJavascript file, html if compress

  html = "<script type='text/javascript'>\n#{html}\n</script>"
  #将新的html合并到body里
  $('body').append html
  $.html()

#获取环境变量
getVariables = (silky, server, project_name)->
  previewServer = "http://#{server}.preview.lab.hunantv.com/#{project_name}/"
  cssHunantv = "http://css.hunantv.com/#{project_name}/"
  imgHunantv = "http://img.hunantv.com/#{project_name}/"
  jsHunantv = "http://js.hunantv.com/#{project_name}/"
  imgDemo = "http://image-demo.lab.hunantv.com/#{project_name}/"
  pubTemplate = "/imgotv-pub/template/"
  compDir = "imgotv-pub/component/"
  honeyRootDev = 'http://honey.hunantv.com/honey/src/'
  honeyRootProduction = 'http://honey.hunantv.com/honey-2.0/'

  data =
    preview:
      __css: "#{previewServer}css/"
      __js: "#{previewServer}js/"
      __img: "#{previewServer}image/"
      __pub_img: "#{previewServer}image/imgotv-pub/"
      __img_demo: imgDemo
      __pub_font: "#{previewServer}/font/"
      __base_url: "/#{project_name}/"
      __pub_css_comp: "#{previewServer}css/#{compDir}"
      __honey_root: honeyRootProduction
    development:
      __css: "/css/"
      __js: "/js/"
      __img: "/image/"
      __pub_img: "/imgotv-pub/image/"
      __img_demo: "/image-demo/"
      __pub_font: "/imgotv-pub/font/"
      __base_url: "/"
      __pub_css_comp: "/imgotv-pub/css/component/"
      __honey_root: honeyRootDev
    production:
      __pub_font: "#{cssHunantv}/font/"
      __css: cssHunantv
      __js: jsHunantv
      __img: imgHunantv
      __img_demo: imgDemo
      __pub_img: "#{imgHunantv}imgotv-pub/"
      __base_url: "/#{project_name}/"
      __pub_css_comp: "#{cssHunantv}#{compDir}"
      __honey_root: honeyRootProduction

  variables = data[silky.options.env]

  _.extend variables,
    __standard_css: "http://css.hunantv.com/standard/"
    __pub_tmpl: pubTemplate
    __project: project_name
    __pub_tmpl_comp: "#{pubTemplate}component/"
    __pub_tmpl_ui: "#{pubTemplate}ui/"
    __pub_tmpl_widget: "#{pubTemplate}widget/"
    __is_dev: String(silky.utils.isDevelopment)

  variables

#更改config的配置
appendConfig = (silky)->
  #添加路由配置
  routers = silky.config.routers
  silky.config.routers = routers.concat(
    #图片的转发
    [
      {path: /^.image.imgotv\-pub.(.+)$/i, to: '/imgotv-pub/image/$1', static: true, next: false}
    ]
  )

  build = silky.config.build
  #重命名
  build.rename = build.rename.concat(
    [
      #公共图片
      {source: /^imgotv\-pub.image.(.+)/i, target: '/image/imgotv-pub/$1', next: false}
      #公共的CSS
      {source: /^imgotv\-pub.css.component.(.+)/i, target: '/css/imgotv-pub/component/$1', next: false}
      #公共的字体
      {source: /^imgotv\-pub.font.(.+)/i, target: '/css/imgotv-pub/font/$1', next: false}
      #重命名source的问题
      {source: /source\.(js)$/i, target: '$1', next: false}
    ]
  )

  #忽略掉的文件
  build.ignore = build.ignore.concat(
    [
      #模板中的module
      /^template.module$/i
      #css中的module
      /^css.module$/i
      #以.开头的
      /(^|\/)\.(.+)$/
      #以log为扩展名的
      /\.(log)$/i
      #node_modules，预防性的
      /^node_modules$/i
      #公共库中css的include
      /^imgotv\-pub.css.include$/i
      #不编译公共库的模板
      /^imgotv\-pub.template$/i
    ]
  )

#  console.log build.ignore.length
#  process.exit 0

#  buildRename = silky.config.rename
#  buildRename.push
#    {
#      source: /^imgotv\-pub[\/|\\]\/(.+)/i, target: '/$1', next: false
#    }

#添加系统变量
appendSystemVariable = (silky)->
  project_name = silky.config.name || _path.basename silky.options.workbench

  #server = silky.options.extra
  variables = getVariables silky, 108, project_name

  #把变量加到global中去
  jsonData = silky.data.json
  jsonData.global = jsonData.global || {}
  _.defaults jsonData.global, variables

  #把变量加到less中
  pubLess = "/imgotv-pub/css/";
  pubIncludeLess = "#{pubLess}include/";
  lessData = silky.data.less
  lessData.global = lessData.global || ''
  lessData.global += "
      @__project: '#{variables.__project}';
      @__img: '#{variables.__img}';
      @__pub_img: '#{variables.__pub_img}';
      @__pub_less: '#{pubLess}';
      @__pub_font: '#{variables.__pub_font}';
      @__pub_less_widget: '#{pubIncludeLess}widget/';
      @__pub_less_function: '#{pubIncludeLess}function/';
      @__pub_less_ui: '#{pubIncludeLess}ui/';
      @__module: 'module/';
      @__pub_less_comp: '#{pubLess}component/';
  "


#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  #在build和路由启动的时候，加入系统变量
  silky.registerHook 'route:initial', ->
    appendSystemVariable silky
    appendConfig silky

  silky.registerHook 'build:initial', ->
    #build时没有指定环境，则假定为preview环境
    #如果没有指定环境，则指定为preview环境，以解决上传到预览服务器的路径问题
    #在正式编译的时候，环境会被设置为production环境
    #不再使用preview环境，build直接使用production环境即可
    #silky.options.env = 'preview' if not silky.options.original.env
    appendSystemVariable silky
    appendConfig silky

  silky.registerHook 'route:willResponse', {}, (data, done)->
    url = _url.parse data.request.url
    #非html不用处理
    return if not /\.html$/.test url.pathname
    #在不包含<script honey=的页面，不需要处理
    return if not /<script\s+honey=/i.test data.content
    data.content = combineHoney data.content

  silky.registerHook 'build:willCompress', {async: true}, (data, done)->
    return done null if not /\.html$/.test data.path
    content = _fs.readFileSync data.path, 'utf-8'
    return done null if not /<script\s+honey=/i.test content

    content = combineHoney content
    _fs.outputFileSync data.path, content
    done null

