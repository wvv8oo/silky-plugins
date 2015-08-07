_path = require 'path'
_http = require 'http'
_request = require 'request'
_url = require 'url'
_async = require 'async'
_path = require 'path'

exports.silkyPlugin = true

#注册silky插件
exports.registerPlugin = (silky, pluginOptions)->
  silky.registerHook("plugin:run", {async: true}, (data, done)->

    projectName = silky.config.name || _path.basename(silky.options.workbench)

    console.log "正在获取服务器列表，请稍候..."
    _request 'http://192.168.8.66:1517/api/server', (err, response, result)->
      serverList = JSON.parse result

      index = 0
      _async.whilst(
        (-> index < serverList.items?.length)
        ((done)->
          server = serverList.items[index]
          url = "#{server.server}api/lock/#{projectName}"
          # url = "http://127.0.0.1:1518/api/lock/#{projectName}"
          # console.log url
          _request url, (err, response, locked)->
            locked = JSON.parse locked
            if !locked.owner
              console.log "【#{serverList.items[index].uuid}可用".green
            else
              console.log "【#{serverList.items[index].uuid}】不可用，被#{locked.owner}在#{locked.timestamp}锁定".red
            index++

            done null
        )
        (err, result)-> process.exit 0
      )
  )