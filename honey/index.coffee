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

#添加系统变量
appendSystemVariable = (silky)->
  isProduction = silky.utils.isProduction
  project_name = silky.config.name || _path.basename silky.options.workbench

  cssProduction = "http://css.hunantv.com/#{project_name}/"
  jsProduction = "http://js.hunantv.com/#{project_name}/"
  imgProduction = "http://img.hunantv.com/#{project_name}/"
  pubImgProduction = "#{imgProduction}imgotv-pub/"
  pubFontProduction = "#{cssProduction}imgotv-pub/font/"
  pubCssProduction = "http://css.hunantv.com/imgotv-pub/"
  pubCssCompProduction = "http://css.hunantv.com/standard/"

  pubTemplate = "/imgotv-pub/template/"
  variables =
    #公共的css路径
    __pub_css: if isProduction then pubCssProduction else "/imgotv-pub/css/"
    #css的位置
    __css: if isProduction then cssProduction else "/css/"
    #js路径
    __js: if isProduction then jsProduction else "/js/"
    #图片路径
    __img: if isProduction then imgProduction else "/image/"
    #公共模板
    __pub_tmpl: pubTemplate
    #项目名称
    __project: project_name
    #公共库的图片
    __pub_img: if isProduction then pubImgProduction else "/imgotv-pub/image/"
    #公共库的字体
    __pub_font: if isProduction then pubFontProduction else "/font/"
    #公共模板
    __pub_tmpl_comp: "#{pubTemplate}component/"
    #__pub_tmpl_module: "#{pubTemplate}module"
    __pub_tmpl_ui: "#{pubTemplate}ui"
    __pub_tmpl_widget: "#{pubTemplate}widget/"
    #全局组件的css
    __pub_css_comp: if isProduction then pubCssCompProduction else "/imgotv-pub/css/component/"
    #demo图片的地址
    __img_demo: if isProduction then "http://image-demo.lab.hunantv.com/#{project_name}/" else "/image-demo/"

  #把变量加到global中去
  jsonData = silky.data.json
  jsonData.global = jsonData.global || {}
  _.defaults jsonData.global, variables

  #把变量加到less中
  pubLess = "../imgotv-pub/css/";
  pubIncludeLess = "#{pubLess}include";
  lessData = silky.data.less
  lessData.global = lessData.global || ''
  lessData.global += "
      @__project: '#{variables.__project}';
      @__img: '#{variables.__img}';
      @__pub_img: '#{variables.__pub_img}';
      @__pub_less: '#{pubIncludeLess}';
      @__pub_font: '#{variables.__pub_font}';
      @__pub_less_widget: '#{pubIncludeLess}/widget/';
      @__pub_less_function: '#{pubIncludeLess}/function/';
      @__pub_less_ui: '#{pubIncludeLess}/ui/';
      @__module: 'module/';
  "

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  #在build和路由启动的时候，加入系统变量
  silky.registerHook 'route:initial', -> appendSystemVariable silky
  silky.registerHook 'build:initial', -> appendSystemVariable silky

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

