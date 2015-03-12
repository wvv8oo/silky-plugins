#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 3/12/15 3:28 PM
#    Description:

_path = require 'path'
_fs = require 'fs-extra'

mergeJavascript = (output, rule)->
  source = rule.source.concat ['head.load.js', 'honey.js']
  content = ''
  for file in source
    file = _path.join output, file
    content += _fs.readFileSync file, 'utf-8'

  target = _path.join output, rule.target
  _fs.outputFileSync target, content

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  #build完成后，提交到指定服务器
  silky.registerHook 'build:didMake', {}, (data, done)->
    #合并honey的文件
    rules = [
      {
        target: 'honey.hunantv.imgo.js'
        source: [
          'configs/config.hunantvimgotv.js'
        ]
      }
      {
        target: 'honey.newhunantv.js'
        source: [
          'configs/config.hunantvimgotv.js'
        ]
      }
      {
        target: 'honey.mobile.js'
        source: [
          'configs/config.mobile.js'
        ]
      }
    ]

    mergeJavascript data.output, rule for rule in rules
    _fs.removeSync _path.join(data.output, 'configs')