_path = require 'path'
_fs = require 'fs-extra'

#合并文件夹中的所有js文件，并命名为index.js
mergeModuleAsIndex = (dir)->
  onlyFile = _path.join(dir, 'index.js')
  contents = []

  _fs.readdirSync(dir).forEach (filename)->
    #跳过index
    return if /index\.js$/i.test filename

    moduleName = "#{_path.basename(dir)}/#{filename.replace('.js', '')}"
    file = _path.join dir, filename
    content = _fs.readFileSync file, 'utf-8'
    content = content.replace(/(define\()\[/i, "$1\"./#{moduleName}\", [")
    contents.push content
    #删除这个文件
    _fs.removeSync file

  contents.push _fs.readFileSync(onlyFile, 'utf-8')
  _fs.outputFileSync onlyFile, contents.join('')

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky)->
  #在预处理结束后，合并掉指
  silky.registerHook 'build:didMake', {}, (data, options, done)->
    jsPath = _path.join data.output, 'js'
    modules = ['assets', 'comment', 'commit', 'global-directives',
               'issue', 'member', 'project', 'services', 'report']

    mergeModuleAsIndex _path.join(jsPath, module) for module in modules