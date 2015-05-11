###配置说明
------------

```
defaultConfig = {
  "tmpDir": _path.join(_os.tmpDir(), 'silky-upload-client'), #临时文件夹
  "src": "image-demo", #需要上传的文件夹
  "server": "http://image-demo.lab.hunantv.com", #服务器相关配置
  "method": {
    upload: "/upload", #文件上传路径
    vertify: "/vertify" #文件校验路径
  }
}
```

##### tempDir
可使用默认值，不需要进行设置。
该值用于存放临时文件，进行压缩校验

##### src
该值可以使用默认值```image-demo```, 不需要进行设置。
该值设置需要上传图片所在的文件夹

##### server
该值需要进行设置，执向服务端接收图片的地址,可使用默认值

##### method
不需要修改



