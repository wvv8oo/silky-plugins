#    Author: 易晓峰
#    E-mail: wvv8oo@gmail.com
#    Date: 1/29/15 11:32 AM
#    Description: 构建markdown的索引

_path = require 'path'
_fs = require 'fs-extra'
_ = require 'lodash'
_md2json = require 'md2json'

_utils = require './utils'

_cache =
  #已经排序好的页
  sortedPages: []
  #已经排序好的文章
  sortedPosts: []
  #文章的内容，如果需要缓存内容的话
  postContents: []
  #原始文章，没有排序，原始的文章信息，不包含文章内容
  originPosts: []
  #原始标签
  originTags: []
  #key/value索引，以url为key
  indexes:
    #文章
    posts: {}
    #标签与文章的索引{"tag": {index: 10, posts: [0, 1, 3]}}
    tags:{}

#  准备构建新的缓存
exports.initial = (rootDir)->
  filter = /\.(md|markdown|txt)$/i
  _md2json.scan rootDir, filter, null, (post, filename, stat)->

    return if not post

    nameWithoutExt = _path.basename(filename, _path.extname(filename))
    post.title = post.title || nameWithoutExt
    post.link = post.link || nameWithoutExt
    post.type = post.type || 'post'
    post.excerpt = post.excerpt || post.content.substr(0, 100)
    post.publish_date = post.publish_date || stat.mtime
    post.url = _utils.getPostUrl post.type, post.link

    post.tags = post.tags.split(',') if post.tags

    exports.appendPost post, filename

  exports.indexMaker()

#  构建索引，并排序
exports.indexMaker = ->
  #排序的文章
  posts = sortPost(_cache.originPosts)

  #过滤出post
  _cache.sortedPosts = _.filter(posts, (item) ->
    type = _cache.originPosts[item].type
    not type or type is "post"
  )

  #过滤出page
  _cache.sortedPages = _.filter(posts, (item) ->
    _cache.originPosts[item].type is "page"
  )

  #将indexes中的所有标签文章进行排序
  _cache.originTags.forEach (tag) ->
    #找到索引中对应标签的所有文章
    keyTag = getTagKey(tag)
    posts = sortPost(_cache.indexes.tags[keyTag].posts, (index) ->
      _cache.originPosts[index]
    )

    #tag只匹配post
    _cache.indexes.tags[keyTag].posts = _.filter(posts, (item) ->
      _cache.originPosts[item].type is "post"
    )


#  根据url，获取文章的内容
#  @param {String} url - 要获取文章的url
exports.getPostContent = (url) ->
  #找到实际的索引
  realIndex = _cache.indexes.posts[url]
  return if realIndex is undefined
  _cache.postContents[realIndex]

#  添加文章
#  @param {Object} post - 文章的JSON对象
exports.appendPost = (post, cacheContent) ->
  #检查相同的链接是否已经存在
  exists = _cache.indexes.posts[post.link]
  if exists isnt undefined
    return console.log "抛弃url已经存在的文章，url: %s，标题：%s", post.url, post.title

  if post.status is "draft"
    return console.log "忽略草稿【%s】", post.title

  #缓存文章的内容
  _cache.postContents.push post.content  if cacheContent
  postIndex = _cache.originPosts.push(post) - 1

  #添加索引中的文章信息，以link为key
  _cache.indexes.posts[post.url] = postIndex

  #抛弃内容
  delete post.content
  appendTags post.tags, postIndex

#
#  查找获取文章
#  @param {Object} options - 选项
#    var options = {
#      //开始位置
#      start: 1,
#      //结束位置
#      end: 5,
#      //指定标签下的文章
#      tag: null
#    }
#
exports.findPost = (options) ->
  ops =
    #开始的位置
    start: 0
    #结束的索引位置
    end: 5
    #指定tag
    tag: null

  #合并参数
  ops = _.extend(ops, options)

  #获取指定位置的数据
  data = undefined
  find = undefined
  if ops.tag and (find = _cache.indexes.tags[getTagKey(ops.tag)])
    data = find.posts
  else
    data = _cache.sortedPosts

  #返回文章的详细数据
  _.map data.slice(ops.start, ops.end), (num) ->
    post = _cache.originPosts[num]


#  返回文章的总数量
#  @param {undefined | String} tag - 如果指定标签，则返回该标签下的文章
#  @returns {Number} 根据条件，返回文章的总数量
exports.postCount = (tag) ->
  if tag
    tagIndex = _cache.indexes.tags[tag]
    if tagIndex then tagIndex.posts.length else 0
  else
    _cache.originPosts.length

#  获取一篇文章
#  @param {String} url - 文章的url
#  @param {String} tag - 某个指定tag下的文章，用于获取上一下和下一篇
exports.onePost = (url, tag) ->
  #找到实际的索引
  realIndex = _cache.indexes.posts[url]
  return if realIndex is undefined
  post = _cache.originPosts[realIndex]
  post = _.extend({}, post)
  post.content = _cache.postContents[realIndex]

  #获取上一篇和下一篇文章
  postIndexes = _cache.sortedPosts
  tagIndex = undefined
  postIndexes = tagIndex.posts  if tag and (tagIndex = _cache.indexes.tags[tag])

  #下一条
  post.previous = getSiblingpost(postIndexes, realIndex, "previous")
  #下一条
  post.next = getSiblingpost(postIndexes, realIndex, "next")
  post

#  获取所有的page
exports.pages = ->
  _.map _cache.sortedPages, (item) ->
    post = _cache.originPosts[item]
    {
      url: post.url
      link: post.link
      title: post.title
    }


#
#  查找标签
#  @param {Object} options - 选项
#  var options = {
#    //开始位置
#    start: 1,
#    //结束位置
#    end: 5
#  }
#
exports.findTag = (options) ->
  ops =
    start: 0
    end: _cache.originTags.length

  ops = _.extend(ops, options)
  _cache.originTags.slice ops.start, ops.end

#  添加标签
appendTags = (tags, postIndex) ->
  _.each _.uniq(tags), (tag) ->
    tagKey = getTagKey(tag)
    #计数标签
    find = _cache.indexes.tags[tagKey]

    #将文章加入到标签的索引中
    return find.posts.push postIndex if find

    #创建新的索引
    _cache.indexes.tags[tagKey] =
      index: _cache.originTags.push(tag) - 1
      posts: [postIndex]

#  对文章进行排序
sortPost = (posts, findPost) ->
  #提取文章发布日期和索引信息
  posts = _.map(posts, (item, index) ->
    post = (if _.isFunction(findPost) then findPost(item) else item)
    return{
      #发布日期
      publish_date: post.publish_date
      #原始索引
      index: index
    }
  )

  #排序后的结果
  posts = sortPostByDate(posts)
  #返回索引排序信息
  _.map posts, (post) -> post.index


#根据日期重新排序文章
sortPostByDate = (posts) ->
  posts.sort (left, right) -> if left.publish_date > right.publish_date then -1 else 1

#  获取相临近的文章，用于获取上一篇/下一篇
#  @param {Number} realIndex - 在originpost中的实际索引
getSiblingpost = (posts, realIndex, direction) ->
  find = _.indexOf(posts, realIndex)
  return false if find is -1

  sibling = false
  #下一条记录
  if direction is "next"
    #没有下一条了
    sibling = find + 1  if find < posts.length - 1
  else
    sibling = find - 1  if find > 0

  return false if sibling is false

  #找到索引
  post = _cache.originPosts[posts[sibling]]

  #只返回链接与标题
  return {
    link: post.link
    url: post.url
    title: post.title
  }

getTagKey = (tag) ->
  return tag
  #需要考虑大小写去重，暂时放弃
  tag.toLowerCase()