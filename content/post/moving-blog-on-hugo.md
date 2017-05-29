+++
date = "2017-05-29T13:47:18+03:00"
title = "Moving the blog on hugo."
+++

It's been, unfortunately usual, long pause in my writing mainly caused by huge workload and lack of time and themes to cover. I had several posts as drafts, but failed to write them to the end. Instead as a kind of escape from dead end I was stuck in, I decided to move the blog from [jekyll](https://jekyllrb.com) to [hugo](https://gohugo.io). And additionally give it a distinctive name, though it is still hosted on the github pages.

<!--more-->

The main hugo's advantage over jekyll is that it does not depend on any commit hooks, what you see locally is what you get once it is published to your blog. I faced with a few issues when the blog was served by jekyll: pagination fails, configuration issues. Now static content is generated and published, so all the problems, I hope, in the past

There is a minor problem with hugo and github, though. If you want to use github provided doman as `<usename>.github.io`, you will have to bother with sub-repositoried and stuff like that. Merely because in such case you're allowed to serve all static content from the root of the repository only. But this blog, being hosted on custom domain, caused me no any problems. I just put all generated files to the `/docs` folder. Github allows to serve a site from the `/docs` folder fortunately. 

I won't bother copy/pasting [hugo](https://gohugo.io) and github manuals here, it makes no sense. But if you want to know how this blog is built, you can alway take a look at my [repository](https://github.com/raol/raol.io). As for custom domain, more information on how connect it to the github pages is [here](https://help.github.com/articles/quick-start-setting-up-a-custom-domain/).
