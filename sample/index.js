/**
 * Created by wvv8oo on 1/26/15.
 * 支持javascript和coffeescript
 */

/*
 更多的hook如下，具体的hook使用方法，请参考API文档

 initial: 'route:initial'
 willPrepareDirectory: 'route:willPrepareDirectory'
 didPrepareDirectory: 'route:didPrepareDirectory'
 willResponse: 'route:willResponse'
 willCompress: 'build:willCompress'
 didCompress: 'build:didCompress'
 willBuild: 'build:willBuild'
 didBuild: 'build:didBuild'
 willCompile: 'build:willCompile'
 didCompile: 'build:didCompile'
 willProcess: 'build:willProcess'
 didProcess: 'build:didProcess'
 */

//声明这是一个silky插件，必需存在
exports.silkyPlugin = true;

//注册silky插件
exports.registerPlugin = function(silky, options) {
  //注册handlebars的helper，关于handlebars，请参考：http://handlebarsjs.com/
  silky.registerHandlebarsHelper('customCommand', function(value, done) {
    //直接返回value，什么也不做，你可以根据需要返回具体的数据
    return value
  });

  //将要响应路由时hook
  silky.registerHook('route:willResponse', {async: true}, function(data, done) {
    //如果是html文件，则在最后面加上一个时间戳
    if (/\.html$/.test(data.request.url)) {
        var extendText = "<!--" + new Date() + "-->";
        data.content += extendText;
    }
    //异步后的回调
    done(null)
  });

  //注册一个编译器
  silky.registerCompiler('jade', {capture: 'jade', target: 'html'}, function(source, option, cb){
    //调用编译器编译模板
  })
};