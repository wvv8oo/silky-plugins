#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 5/20/15 3:01 PM
#    Description: 合并honey以及component的css
_cheerio = require 'cheerio'
_ = require 'lodash'
_fs = require 'fs-extra'
_path = require 'path'

#全局的css路径
_globalCSS = '/css/imgotv-pub/global.css'
#所有的component/css
_componentCSS = []

#合并honey
mergeHoney = (silky, $)->
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
  html = "\thoney.go(\"#{_.unique(deps).join(',')}\", function() {\n"
  #将所有的代码都封装到闭包中运行
  for script in scripts
  #不处理空的script
    html += "\t(function(){\n#{script}\n\t}).call(this);\n\n"
  html += '\n\t});'

  html = "<script type='text/javascript'>\n#{html}\n</script>"
  #将新的html合并到body里
  $('body').append html


#分析提取component/css
analyseComponentCSS = (silky, $)->
  $("link[type='component/css']").each ->
    $this = $(this)
    link = $this.attr 'href'
    link = link.replace silky.data.json.global.__css, 'css/'
    _componentCSS.push link
    $this.remove()

#  #替换global.css
#  href = silky.data.json.global.__css + _globalCSS
#
#  $links = $("link[data-merge]")
#  if $links.length > 0
#    $links.attr 'href', href
#  else
#    #插入一个新的css
#    $('head').append("<link href='#{href}' rel='stylesheet' type='text/css' />")

exports.execute = (silky, data, content, makeCSS)->
  #是否需要合并honey
  makeHoney = /<script\s+honey=/i.test content
  #是否需要合并css
  makeCSS = makeCSS and /component\/css/mig.test content

  #不需要合并任何的内容
  return content if not (makeCSS || makeHoney)

  $ = _cheerio.load content
  mergeHoney silky, $ if makeHoney
  analyseComponentCSS silky, $ if makeCSS
  $.html()

#合并所有的component到global.css
exports.mergeGlobalCSS = (silky, data)->
  files = _.unique _componentCSS
  #globalCSSFile = "/css/imgotv-pub/" + _globalCSS
  return if not (files and files.length)
  files.unshift _globalCSS

  target = _path.join silky.options.output, _globalCSS
  targetDir = _path.dirname target
  #确保文件夹存在
  _fs.ensureDirSync targetDir

  content = ''
  _.map files, (file)->
    file = _path.join data.output, file
    return if not _fs.existsSync file

    content += silky.utils.readFile file
    #合并后，删除这个文件，因为这个文件已经没用了
    _fs.removeSync file

  silky.utils.writeFile target, content