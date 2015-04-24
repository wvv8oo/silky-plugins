## babel-compiler

提供两个编译器，`babel.jsx`用于编译react的jsx文件；`babel.es6`用于将es6编译为es5。

## 安装

`sudo silky install babel-compiler`，windows不需要sudo

## 配置

请在`.silky/config.js`文件中配置编译器，也可以参考sample中的示例项目。

````
compiler: {
    //根据路由规则匹配编译器
    rules: [
        //将es6文件夹下所有的js，都交给es6编译器处理
        {path: /es6\/.+\.js$/i, compiler: "babel.es6"},
        //将react文件夹下的所有js，都交给react编译器处理
        {path: /react\/.+\.js$/i, compiler: "babel.jsx"}
    ],
    //或者根据扩展名匹配，适用于所有的js都采用同一个编译器
    extension: {
        //将所有js扩展名的文件，都交给babel.jsx编译器处理
        js: 'babel.jsx',
        //将所有js扩展名的文件，都交给babel.es6编译器处理
        //js: 'babel.es6'
    }
}
````