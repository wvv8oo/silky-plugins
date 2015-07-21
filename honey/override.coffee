#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 5/20/15 2:54 PM
#    Description: 覆写全局变量和配置文件
_ = require 'lodash'
_path = require 'path'

#获取环境变量
getVariables = (silky, server, project_name)->
  previewServer = "http://#{server}.preview.lab.hunantv.com/#{project_name}/"
  cssHunantv = "http://css.hunantv.com/#{project_name}/"
  imgHunantv = "http://img.hunantv.com/#{project_name}/"
  jsHunantv = "http://js.hunantv.com/#{project_name}/"
  imgDemo = "http://192.168.8.108:12288/#{project_name}/"
  pubTemplate = "/imgotv-pub/template/"
  compDir = "imgotv-pub/component/"
  honeyRootDev = 'http://honey.hunantv.com/src/'
  honeyRootProduction = 'http://honey.hunantv.com/honey-2.0/'

  data =
    preview:
      __css: "#{previewServer}css/"
      __pub_css: "#{previewServer}css/imgotv-pub/"
      __js: "#{previewServer}js/"
      __img: "#{previewServer}image/"
      __pub_img: "#{previewServer}image/imgotv-pub/"
      __img_demo: imgDemo
      __pub_font: "#{previewServer}font/"
      __base_url: "/#{project_name}/"
      __pub_css_comp: "#{previewServer}css/#{compDir}"
    development:
      __css: "/css/"
      __pub_css: "/imgotv-pub/css/"
      __js: "/js/"
      __img: "/image/"
      __pub_img: "/imgotv-pub/image/"
      __img_demo: "/image-demo/"
      __pub_font: "/imgotv-pub/font/"
      __base_url: "/"
      __pub_css_comp: "/imgotv-pub/css/component/"
    production:
      __pub_font: "#{cssHunantv}font/"
      __css: cssHunantv
      __pub_css: "#{cssHunantv}imgotv-pub/"
      __js: jsHunantv
      __img: imgHunantv
      __img_demo: imgDemo
      __pub_img: "#{imgHunantv}imgotv-pub/"
      __base_url: "/#{project_name}/"
      __pub_css_comp: "#{cssHunantv}#{compDir}"

  variables = data[silky.options.env]

  _.extend variables,
    __standard_css: "http://css.hunantv.com/standard/"
    __pub_tmpl: pubTemplate
    __project: project_name
    __pub_tmpl_comp: "#{pubTemplate}component/"
    __pub_tmpl_ui: "#{pubTemplate}ui/"
    __pub_tmpl_widget: "#{pubTemplate}widget/"
    __honey_is_dev: false
    __is_dev: String(silky.utils.isDevelopment)
    __honey_root: honeyRootProduction

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
#    [
#      {path: /^.css.global.css$/i, to: '/imgotv-pub/css/global.css', static: false, next: false}
#    ]
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
      #处理imgotv-pub根目录下的less和css
      {source: /^imgotv\-pub.css.global\.(css|less)$/i, target: '/css/imgotv-pub/global.css', next: false}
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

#覆盖less的变量，跳过已经存在的变量
overrideLessVariable = (data, key, value)->
  key = "@#{key}"
  reg = new RegExp "#{key}(\s+)?:.+;"
  #global.less的变量已经存在，不再处理
  return data if reg.test data

  data += "\n#{key}: \"#{value}\";";

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

  lessVariables =
    __project: "#{variables.__project}"
    __img: "#{variables.__img}"
    __pub_img: "#{variables.__pub_img}"
    __pub_less: "#{pubLess}"
    __pub_font: "#{variables.__pub_font}"
    __pub_less_widget: "#{pubIncludeLess}widget/"
    __pub_less_function: "#{pubIncludeLess}function/"
    __pub_less_ui: "#{pubIncludeLess}ui/"
    __module: "module/"
    __pub_less_comp: "#{pubLess}component/"

  for key, value of lessVariables
    lessData.global = overrideLessVariable lessData.global, key, value

exports.convert = (silky)->
  appendSystemVariable silky
  appendConfig silky