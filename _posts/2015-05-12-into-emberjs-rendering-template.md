---
layout: page
title: "Into Emberjs: Rendering Template"
date: 2015-05-12
summary: |
tags: emberjs render
---

在ember中可以很灵活的操作模板的插入, 一个比较典型的例子就是模态对话框的显示和关闭. 以往的实现是通过js控制css的属性达到对话框的隐藏和显示, 或者是通过后端返回的模板进行dom的插入和删除操作, 我们如何通过前端ember框架来实现类似的效果呢. 首先我们需要认识render.

## Render

在ember中render的任务是交给route中的, 比如我们先定义一个route

```js
App.PostRoute =  Ember.Route.extend();
```

> 默认这个PostRoute会找到post.hbs进行渲染, 当然ember还提供方法自定义模板的渲染

```js
export default Ember.Route.extend({
  renderTemplate: function() {
    this.render('favoritePost');
  }
});
```

> 这里就用到了render方法, render 方法可以很灵活的去定制渲染的模板, 甚至自定需要的controller和model. 请看下面这个例子

```js
# app/route/posts.js
export default Ember.Route.extend({
  renderTemplate: function() {
    this.render('favoritePost', {   // the template to render
      into: 'posts',                // the template to render into
      outlet: 'posts',              // the name of the outlet in that template
      controller: 'blogPost'        // the controller to use for the template
    });
```

对应的模板为

```handlebars
# app/templates/posts.hbs
this is posts template
{{outlet "posts"}}
```

```handlebars
# app/templates/favoritePost.hbs

<div>this is my fav post</div>
```

* render 中的第一个参数是我们需要渲染的模板, 实际ember会通过该名字去找到对应在templates下的模板, 所以如果有层级关系需要写成类似`modals/favoriatePost`这样的名字
* into: 我把它理解为渲染所需要的layout模板
* outlet: 告诉需要渲染的模板要放到layout中的哪里
* controller: 模板对应需要的controller
* model: controller需要的model
* view: 模板需要的view

那么上面的例子实际渲染的效果就是
```html
this is posts template

<div>this is my fav post</div>
```

## Back to our Modal

我们需要:

1. 一个统一的service控制模态窗口的显示和关闭逻辑
2. 模态窗口可以填充任意的内容
3. 窗口可以在所有页面被方便调用

为了使窗口可以在所有的页面被调用, 可以把入口添加到application.hbs 这个layout 模板中

```handlebars
<header>
    <article>
        <div class="row">
            <h1 class="col-sm-3">
                <a href="#">Ember Crm</a>
            </h1>
            <div class="col-sm-9">
                <a class="actions pull-right" {{action "showHello"}}>Sign Up</a>
            </div>
        </div>
    </article>
</header>
<section id="main">
    <button type="submit" {{action 'successMsg'}}>Success Message</button>
    <button type="submit" {{action 'errorMsg'}}>Error Message</button>
    {{msg-queue}}
    {{outlet}}
</section>
{{outlet "modal-body"}}
<footer></footer>
```

然后创建一个单例service, 叫做ModalBodyService

```js
Crm.ModalBodyService = Ember.Object.extend

  rootRoute: (->
    @container.lookup("route:application")
  ).property()
  
  openModal: (name, options)->
    controller = @container.lookup("controller:#{name}")
    renderOptions = Em.merge({
      into: "application",
      outlet: "modal-body",
      controller: controller,
      view: 'modal-body'
    }, options)
    @get('rootRoute').render("modals/#{name}", renderOptions)

  closeModal: ->
     @get("rootRoute").disconnectOutlet({
      outlet: 'modal-body',
      parentView: 'application'
    })
```

为了让controller和route都可以调用service的openModal 和closeModal方法, 我们需要将器注入到各组件中

```js
Crm.register("service:modal-body", Crm.ModalBodyService)
Em.A(["controller", "route", "component"]).forEach((item)->(Crm.inject(item, "modalBody", "service:modal-body")))
```

这样, route就可以调用出modal对话框了

```js
this.get('modalBody').openModal("hello")
# open hello modal box
```

还没完呢, 由于本例中我们使用了bootstrap的modal, 当modal的html被添加到页面上后, 窗口并不会弹出来, 而是需要调用其js, 显而易见, 为了让html在加入到页面上后调用js,需要额外的再做一步

```js
Crm.ModalBodyView = Ember.View.extend
  classNames: ["modal"]

  showModal: (->
    @.$().modal({"show": true})
  ).on("didInsertElement")
```

这样我们就做出了ember下的一个简单的模态窗口服务
