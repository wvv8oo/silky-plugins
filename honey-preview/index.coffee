#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/9/15 9:38 AM
#    Description:

_path = require 'path'
_fs = require 'request'
_child = require 'child_process'
_request = require 'request'
_fs = require 'fs'

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  #build完成后，提交到指定服务器
  silky.registerHook 'build:didBuild', {async: true}, (data, done)->
    projectName = pluginOptions.projectName || _path.basename(silky.options.workbench)
    server = silky.options.extra || pluginOptions.server
    #用户没有指定全url
    server = "http://192.168.8.#{server}:1518" if server.indexOf('http://') < 0
    #兼容windows，使用绝对路径tar打包会报错
    ﻿tarFile =  "../#{projectName}.tar"

    #打包项目
    packageProject(data.output, tarFile, (err)->
      tarFile = _path.join data.output, tarFile
      deliverProject tarFile, projectName, server, (err)->
        _fs.unlinkSync tarFile
        done null
    )

#对文件进行打包
packageProject = (output, tarFile, cb)->
  command = "cd \"#{output}\" && tar -cf \"#{tarFile}\" ."
  options =
    env: process.env
    maxBuffer: 20 * 1024 * 1024

  console.log "准备打包文件..."
  exec = _child.exec command, options
  exec.on 'close', (code)->
    if code isnt 0
      message = "打包文件失败，请检查是否可以使用tar命令"
      console.log message.red
      return process.exit 1

    cb null

  exec.stdout.on 'data',  (message)->
    console.log message

  exec.stderr.on 'data', (message)->
    console.log message.red

#分发项目
deliverProject = (tarFile, projectName, server, cb)->
  console.log "正在分发到服务器"
  console.log "服务器： #{server}"
  console.log "项目：#{projectName}"
  console.log "打包文件：#{tarFile}"

  formData = projectName: projectName
  formData.attachment = _fs.createReadStream tarFile

  options =
    url: server
    method: 'POST'
    json: true
    formData: formData
    timeout: 1000 * 60 * 30

  _request options, (err, res, body)->
    console.log JSON.stringify(err).red if err

    if res.statusCode isnt 200
      message = '代理服务器返回状态码不正确，请检查'
      console.log message.red
      err = new Error(message)

    return cb err if err

    console.log "分发成功 -> #{JSON.stringify(body)}".green
    console.log "参考访问地址：http://honey2.hunantv.com/#{projectName}"
    cb err