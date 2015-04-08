#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 2/2/15 2:48 PM
#    Description: 生成rss

_path = require 'path'
_marked = require 'marked'
_rss = require 'rss'

_storage = require './storage'
_utils = require './utils'

#生成rss
exports.generator = ()->
  pluginOptions = _utils.global.options
  blog = pluginOptions.blog

  feed = new _rss
    title: blog.title
    description: blog.description
    feed_url: blog.feed
    site_url: blog.url
    author: blog.author
    managingEditor: blog.author
    webMaster: blog.author
    copyright: '&copy; ' + blog.author
    pubDate: new Date().toUTCString()
    ttl: '60'

  #读取指定长度的文章
  options =
    start: 0
    end: pluginOptions.rssLimit || 20

  posts = _storage.findPost(options)

  #获取前面的post
  posts.forEach (post) ->
    url = _path.join(blog.host, post.link)
    item =
      title: post.title
      url: url
      author: post.author || ''
      categories: post.tags || [1]
      date: new Date(post.publish_date).toUTCString()

    #获取全文
    if pluginOptions.rss?.full
      item.description = _marked(_storage.getPostContent(post.url))
    else
      item.description = post.excerpt
    feed.item item

  feed.xml()