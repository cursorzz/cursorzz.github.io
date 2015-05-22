---
layout: page
title: "Ember Dependency Injection"
alias: /
date: 2015-05-11
summary: |
category: emberjs
tags: emberjs javascript
---

在ember中, 我们经常需要定义一个service, 并且在很多的组件中使用到它, 这个时候就需要用到injection . 下面我们来完成一个全局的消息通知中心服务, 任何controller, routes, component都可以向这个消息中心推送消息.

先创建一个service

```coffeescript
# services/message-queue.js.coffee
Crm.MessageQueueService = Em.ArrayProxy.extend

  initQueue: (->
    @set('content', [])
  ).on('init')

  pushMessage: (options) ->
    @pushObject(options)
    Em.run.later(@, 'removeMessage', options, 2000)

  removeMessage: (options)->
    @removeObject(options)
```

>这个MessageQueueService在初始化的时候为空数组, 可以通过pushMessage 添加元素, 2000 ms 后去除掉这个元素

现在将它注入controller, component和route

```coffeescript
# /initializers/inject-message-queue.js.coffee
Crm.register('message:queue', Crm.MessageQueueService)

# inject format (full_name or type) (property_name) full_name
Crm.inject('controller', 'messageQueue', 'message:queue')
Crm.inject('route', 'messageQueue', 'message:queue')
Crm.inject('component', 'messageQueue', 'message:queue')
```

>这样所有的controller, route, component都可以这样推送消息了: `this.get('messageQueue').pushMessage({message:"some message", type:'success'})`

ok, 现在在页面上添加对应的元素, 这里创建了两个component: msg-queue 和 msg-blk

```handlebars
# templetes/application.hbs
<header>
    <article>
        <div class="logo">
            <h1><a href="#">Ember Crm</a></h1>
        </div>
    </article>
</header>
<section id="main">
    <button type="submit" {{action 'successMsg'}}>Success Message</button>
    <button type="submit" {{action 'errorMsg'}}>Error Message</button>
    {{msg-queue}}
    {{outlet}}
</section>

<footer></footer>
```

添加msg-queue组件到application.hbs, 因为所有的模板都继承于application.hbs, 所以页面上都会有消息中心, 另外我们添加了两个按钮, 分别发送successMsg 和 errorMsg, 以便测试消息中心的功能

```coffeescript
# routes/application.js.coffee
Crm.ApplicationRoute = Em.Route.extend
  actions:
    successMsg: ->
      @get('messageQueue').pushMessage({type:"success", message: 'this is a success message'})

    errorMsg: ->
      @get('messageQueue').pushMessage({type:"error", message: 'this is a error message'})
```

接下来是msg-queue

```coffeescript
# components/msg-queue.js.coffee
Crm.MsgQueueComponent = Em.Component.extend
  classNames: ['queue']
```

```handlebars
# templetes/components/msg-queue.js.coffee
{{#each message in messageQueue}}
    {{msg-blk model=message }}
{{/each}}
```

最后添加处理单个消息的component

```coffeescript
# components/msg-blk.js.coffee
iconMaps = {
  success: 'success',
  error: 'error'}

Crm.MsgBlkComponent = Em.Component.extend
  classNames: ['message']
  classNameBindings: ['icon']
  
  # Public API
  model: null

  icon: (->
    iconMaps[@get('model.type')]
  ).property('model.type')
```

```handlebars
# templetes/msg-blk.hbs
{{model.message}}
```
