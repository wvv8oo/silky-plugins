_cheerio = require 'cheerio'
_ = require 'lodash'

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
  #html = _jspretty html, indent_size: 4
  html = "<script>\n#{html}\n</script>"

  #将新的html合并到body里
  $('body').append html
  $.html()

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky)->
  silky.registerHook 'route:willResponse', {}, (data, options, done)->
    #非html不用处理
    return if not /\.html$/.test data.request.url
    #在不包含<script honey=的页面，不需要处理
    return if not /<script\s+honey=/i.test data.content
    data.content = combineHoney data.content
    return
