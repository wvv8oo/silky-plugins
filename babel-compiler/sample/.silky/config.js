module.exports = {
    //配置文件的版本，和silky的版本无关
    version: 0.2,
    //80端口在*nix下需要sudo
    port: 14422,
    compiler: {
        //根据路由规则匹配编译器
        rules: [
            //将es6文件夹下所有的js，都交给es6编译器处理
            {path: /es6\/.+\.js$/i, compiler: "babel.es6"},
            //将react文件夹下的所有js，都交给react编译器处理
            {path: /react\/.+\.js$/i, compiler: "babel.jsx"}
        ]
    },
    //build的配置
    build: {
        //构建的目标目录，命令行指定的优先
        output: "./build",
        ignore: [/^module$/i],
        //是否压缩
        compress: {
            //将要忽略压缩的文件
            ignore: [],
            //压缩js，包括coffee
            js: true,
            //压缩css，包括less
            css: true,
            //压缩html
            html: false,
            //是否压缩internal的js
            internal: true
        }
    }
}
/*
    silky运行的配置文件
 */
