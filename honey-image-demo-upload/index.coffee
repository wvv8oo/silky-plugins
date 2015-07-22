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
exports.silkyPlugin = true

defaultConfig = {
  "tmpDir": _path.join(_os.tmpDir(), 'silky-upload-client'), #临时文件夹
  "src": "image-demo", #需要上传的文件夹
  "server": "http://192.168.8.108:12288", #服务器相关配置
  "method": {
    upload: "/upload", #文件上传路径
    vertify: "/vertify" #文件校验路径
  }
}

getFormData = (file)->
  attachments:
    value: _fs.createReadStream(file)
    options:
      contentType: 'application/x-gzip'

extend = (source, dest = {})->
  dest[x] = source[x] for x of source
  dest

#注册silky插件
exports.registerPlugin = (silky, options)->
  config = extend defaultConfig, options
  TEMPDIR = config.tmpDir
  SERVER = config.server
  METHODS = config.method
  SRCDIR = config.src
  DISTDIR = silky.config.name or silky.options.workbench.split(_path.sep).pop()


  ZIPFOLDER = _path.join TEMPDIR, DISTDIR
  ZIPFILE = "#{ZIPFOLDER}.tar.gz"

  silky.registerHook("plugin:run", {async: true}, (data, done)->
    console.log "----------- Uploading image to server... ----------- "
    #copy Dir To Tmp
    #delete tmp
    tmp = ZIPFOLDER
    #empty tmp directory
    _fse.emptyDirSync(tmp)
    #copy directory
    sourceDir = _path.join process.cwd(), SRCDIR
    _fse.copySync(sourceDir, tmp) if _fs.existsSync(sourceDir)

    #zip and send file
    _fstream.Reader(ZIPFOLDER)
    .pipe(_tar.Pack())
    .pipe(_zlib.Gzip())
    .pipe(_fstream.Writer(ZIPFILE))
    .on('close', ->
      _request
      .post(_url.resolve(SERVER, METHODS.upload), formData: getFormData(ZIPFILE))
      .on('response', ()->
        _fse.emptyDirSync(tmp)
        console.log "----------- Upload image completed! -----------"
        done()
      )
      .on("error", (err)->
        console.log "上传失败！"
        console.error err
      )
    )
  )