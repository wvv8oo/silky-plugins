/**
 * Created by ice on 4/9/15.
 * 支持javascript
 */

//声明这是一个silky插件，必需存在
exports.silkyPlugin = true;

var fs = require('fs'),
    path = require('path')

//注册silky插件
exports.registerPlugin = function(silky, options) {

    var prefix = "/*global_start========================*/\n",
        afterfix = "\n/*========================global_end*/\n"

    silky.registerHook('route:willResponse',  function(data, done) {
        
        if (/\.html$/.test(data.request.url)) {

            var content = data.content,
                pageName = data.request.url.match(/\/(.*?)\.html/)[1],
                //找到目标less
                lessPath = silky.options.workbench + "/css/" + pageName + ".less",
                //搜寻页面上的import
                pageImport = content.match(/\@import url\((.*?)\);/g)

            //页面上的import去重
            pageImport = _singleArrayDeduplication(pageImport)

            var content = fs.readFileSync(lessPath, {
                encoding: 'utf8'
            }),
            //less中
            targetArea = content.match(/\@import url\((.*?)\);/g)

                if (!targetArea) {
                    fs.writeFileSync(lessPath,
                        prefix + pageImport.join("\n") + afterfix + content, {
                            encoding: 'utf8'
                        })

                } else {

                    var target = _arrayDeduplication(pageImport, targetArea)

                    if(target.length == 0) return

                    content = content.toString().replace(/(.+)global(.+)(\n)?/g, "")

                    fs.writeFileSync(lessPath,
                        prefix + target.join("\n")  + afterfix + content, {
                            encoding: 'utf8'
                        })
                }
        }

    });

    
    /**
     * [_singleArrayDeduplication 单个数组去重]
     * @param  {[Array]} arr [数组]
     * @return {[Array]}     [description]
     */
    function _singleArrayDeduplication(arr) {
        var resultObj = {},
            resultArr = []

        for (var a in arr) {
            resultObj[arr[a]] = ""
        }

        for (var r in resultObj) {
            resultArr.push(r)
        }

        return resultArr
    }

    /**
     * [_arrayDedupliaction description]
     * @param  {[Array]} pageArr   [imports list from page]
     * @param  {[Array]} lessArr   [imports list from less]
     * @return {[Array]}           [array after deduplication]
     */
    function _arrayDeduplication(pageArr, lessArr) {

        var pageObj = {},
            lessObj = {},
            joinObj = {},
            resultArr = [],
            lessCotainsPage = false

        for(var l in lessArr) {
            lessObj[lessArr[l]] = ""
        }

        for(var p in pageArr){
            pageObj[pageArr[p]] = ""
        }

        //判断page所有的import是否在less中有
        //如果有，则不做修改
        for(var pl in pageObj) {
            if(typeof(lessObj[pl]) == 'string') lessCotainsPage = true
            else {
                lessCotainsPage = false
                break;
            }
        }

        if(lessCotainsPage) return []

        for(var l in lessObj) {
            joinObj[l] = ""
        }

        for(var p in pageObj) {
            joinObj[p] = ""
        }

        for (var j in joinObj) {
            resultArr.push(j)
        }

        return resultArr
    }

};