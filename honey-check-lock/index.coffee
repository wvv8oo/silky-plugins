_path = require 'path'
_fse = require 'fs-extra'
_fs = require 'fs'
_fstream = require 'fstream'
_tar = require 'tar'
_zlib = require 'zlib'
_http = require 'http'
_request = require 'request'
_url = require 'url'
_os = require 'os'
_async = require 'async'
exports.silkyPlugin = true



#注册silky插件
exports.registerPlugin = (silky, pluginOptions)->
  silky.registerHook("plugin:run", {async: true}, (data, done)->

    projectName = silky.config.name || pluginOptions.project_name || pluginOptions.projectName
    
    _request 'http://192.168.8.66:1517/api/server', (err, response, result)->
        serverList = JSON.parse result

        index = 0
        _async.whilst(
            (-> index < serverList.items?.length)
            ((done)->
              server = serverList.items[index]
              url = "#{server.server}/api/lock/#{projectName}"
              # url = "http://127.0.0.1:1518/api/lock/#{projectName}"
              # console.log url
              _request url, (err, response, locked)->
                locked = JSON.parse locked
                if !locked.owner
                  console.log "【#{serverList.items[index].uuid}】可用".green
                else
                  console.log "【#{serverList.items[index].uuid}】不可用，被#{locked.owner}在#{locked.timestamp}锁定".red
                index++

                done null
            )
            (err, result)->
              
        )
  )