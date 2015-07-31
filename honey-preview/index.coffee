#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/9/15 9:38 AM
#    Description:

_path = require 'path'
_child = require 'child_process'
_request = require 'request'
_fs = require 'fs-extra'
_async = require 'async'
_ = require 'lodash'
_qs = require 'querystring'

DATA =
  apiServer: null
  deliveryServers: null

#标识这是一个silky插件
exports.silkyPlugin = true
#提供注册插件的入口
exports.registerPlugin = (silky, pluginOptions)->
  DATA.apiServer = pluginOptions.task_server || "http://192.168.8.66:1517/api/task"

  #build完成后，提交到指定服务器
  silky.registerHook 'build:didBuild', {async: true}, (data, done)->
    isOutput = _.find process.argv, (current)-> /^\-{1,2}o(utput)?$/i.test current
    if isOutput
      console.log "提示，已经指定本地输出目录，将不会提交至服务器".cyan
      return done null

    projectName = silky.config.name || pluginOptions.project_name || pluginOptions.projectName
    projectName = projectName || _path.basename(silky.options.workbench)

    #分析递送的服务器列表
    DATA.deliveryServers = analysisServer(silky.options.extra || pluginOptions.server)

    if DATA.deliveryServers.length is 0
      console.log "请指定分发服务器，分发失败".red
      return done null

    #打包并分发文件
    packageAndDelivery silky, data.output, projectName, (err)-> done null

#分析多个服务器
analysisServer = (serverText)->
  result = []
  return result if not serverText

  _.map serverText.split(','), (current)->
    if current.indexOf('http://') < 0
      current = "http://192.168.8.#{current}:1518"
    result.push current

  result

#递送到多个服务器
deliveryToMultipleServer = (tarFile, projectName, task, cb)->
  index = 0
  _async.whilst(
    -> index < DATA.deliveryServers.length
    (done)->
      server = DATA.deliveryServers[index++]
      #采用curl的方式上传文件
      deliveryWithCurl tarFile, projectName, server, (err)->
        return done err if err

        #提交部署的任务信息到服务器上
        task.target = server
        task.target = RegExp.$1 if /192\.168\.8.(\d+)/.test task.target

        postTask DATA.apiServer, task, (err)->
          if err
              console.log "分发失败，请查看错误信息 -> #{server}".red
              console.log err
          else
            console.log "分发成功 -> #{server}".green
          done null
    (err)->
      console.log err if err
      #删除文件
      _fs.removeSync tarFile
      cb err
  )


#打包并分发
packageAndDelivery = (silky, output, projectName, cb)->
  #兼容windows，使用绝对路径tar打包会报错
  tarFile = _path.join silky.options.workbench,  "../#{projectName}.tar"
  task = {}

  queue = []

  #打包项目
  queue.push(
    (done)-> packageProject output, tarFile, (err)-> done err
  )


  #收集本地git的信息
  queue.push(
    (done)->
      collectGitInfo (err, data)->
        task = data
        done err
  )

  #分发到多个服务器
  queue.push(
    (done)-> deliveryToMultipleServer tarFile, projectName, task, done
  )

  _async.waterfall queue, cb


#执行命令
executeCommand = (command, cb)->
  options =
    env: process.env
    maxBuffer: 20 * 1024 * 1024

  stdout = ''
  stderr = ''
  exec = _child.exec command, options

  exec.on 'close', (code)->
    if code isnt 0
      console.log "执行命令出错 -> #{command}".red
      console.log
      return process.exit 1
    cb code, stdout, stderr

  exec.stdout.on 'data',  (message)->
    console.log message
    stdout += message

  exec.stderr.on 'data', (message)->
    console.log message
    stderr += message

#分析本地的commit信息
analyzeCommit = (source)->
  result = {}

  pattern = /^commit\s+(.+)\nauthor:\s+.+<(.+)>\ndate:\s+(.+)/i
  result.message = source.replace pattern, (match, hash, email, timestamp)->
    result.hash = hash
    result.email = email
    result.timestamp = new Date(timestamp).valueOf()
    return ''

  result.message = result.message.replace(/\n/, '').trim()
  result


#从本地信息收集git相关的信息，包括commit, author，repos等
collectGitInfo = (cb)->
  data = type: 'preview'
  queue = []

  #获取git的地址
  queue.push(
    (done)->
      command = "git config --get remote.origin.url"
      executeCommand command, (code, stdout, stderr)->
        data.repos_git = stdout.trim()
        data.repos_url = data.repos_git.replace(/^git@(.+):(.+)\.git/i, "http://$1/$2")
        done null
  )

  #获取最后一条git commit
  queue.push(
    (done)->
      command = "git log -n 1"
      executeCommand command, (code, stdout, ssterr)->
        _.extend data, analyzeCommit(stdout)
        data.url = "#{data.repos_url}/commit/#{data.hash}"
        data.repos = data.repos_git
        data.last_execute = new Date().valueOf()
        done null

  )

  _async.waterfall queue, -> cb null, data

#对文件进行打包
packageProject = (output, tarFile, cb)->
  command = "cd \"#{output}\" && tar -cf \"#{tarFile}\" ."

  console.log "准备打包文件..."
  executeCommand command, (code, stdout, stderr)->
    console.log stdout
    console.log stderr
    console.log "文件打包完成"
    cb null

#向hoobot提交
postTask = (task_server, data, cb)->
  options =
    url: task_server
    method: 'POST'
    json: true
    formData: data
    timeout: 1000 * 60 * 30

  _request options, (err, res, body)->
    console.log JSON.stringify(err).red if err
    return cb err if err

    if res.statusCode isnt 200
      message = '向hoobot服务器提交数据失败，请检查'
      console.log message.red
      console.log "Error Code -> #{res.statusCode}".red
      err = new Error(message)
      process.exit 1
    cb err

#通过curl的方式提交数据
deliveryWithCurl = (tarFile, projectName, server, cb)->
  params = _qs.stringify(project_name: projectName)
  command = "curl -X POST -F \"#{params}\" -F \"attachment=@#{tarFile}\" #{server} --connect-timeout 9999999"
  console.log command

  executeCommand command, (code, stdout, stderr)->
    err = null

    if code != 0
      message "分发项目出错，请查询错误信息"
      console.log message.red
      err = new Error(message)

    cb err


#分发项目
deliverProject = (tarFile, projectName, server, cb)->
  console.log "正在分发到服务器"
  console.log "服务器： #{server}"
  console.log "项目：#{projectName}"
  console.log "打包文件：#{tarFile}"

  formData = project_name: projectName
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
    console.log "参考访问地址：http://honey.hunantv.com/#{projectName}/"
    cb err