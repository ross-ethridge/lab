---
layout: post
title:  Build a free, serverless blog with Cloudflare Pages, Jekyll, and R2
date:   2026-01-02 14:00:00 -0600
categories: Code
---

You can host a fast, secure blog for free using:
- Cloudflare Pages for static hosting and Functions
- Jekyll for static site generation
- Optional: Cloudflare R2 for object storage (images, downloads, or future API-backed content)
- Wrangler for local testing

You’ll pay only for your domain. The process below is exactly what I use to deploy the site you’re reading.

Why this stack
- Jekyll turns Markdown into static pages that are simple to build and version in Git.
- Cloudflare Pages serves those files at the edge and can run Functions for dynamic features—no servers to patch or scale.
- R2 stores static assets or data you want to fetch at runtime (e.g., via a Worker or Pages Function) without egress fees to Cloudflare services.

What you’ll build
- A Jekyll site
- Local preview with Wrangler
- A Pages project you can deploy by uploading a ZIP of your built site
- Optional: R2 ready for future dynamic content or asset storage

Prerequisites
- Ruby
  - <a href="https://www.ruby-lang.org/en/documentation/installation/" target="_blank"> Install Ruby </a>
- Jekyll
  - <a href="https://jekyllrb.com/docs/" target="_blank"> Install Jekyll </a>
- Cloudflare account and a domain
  - <a href="https://developers.cloudflare.com/fundamentals/account/create-account/" target="_blank"> Cloudflare Accounts </a>
  - <a href="https://www.cloudflare.com/products/registrar/" target="_blank"> Cloudflare Domains </a>
- Wrangler CLI (installed a bit later)

## Build locally

I'll show you how to create and preview a Jekyll site locally.

```bash
# Install Jekyll & Bundler
gem install jekyll bundler

# Create a new site
jekyll new myblog

# Move into the project
cd myblog

# Serve locally
bundle exec jekyll serve
# Visit http://127.0.0.1:4000/

# To serve on all sddresses so its viewable on the network; add --host
bundle exec jekyll serve --host 0.0.0.0
```
### Build vs serve

Jekyll outputs the production-ready site to the ```_site``` directory.
Use ```serve``` for local preview.  
Use ```build``` when you’re ready to deploy.

```bash
# Build for production (outputs to _site)
bundle exec jekyll build
# Then deploy whatever’s inside _site
```

## Test with Cloudflare Wrangler (Pages emulation)
Preview your Pages deployment locally with Wrangler.  
Wrangler simulates Cloudflare Pages so you can test the exact build output.

Install Wrangler:
- <a href="https://developers.cloudflare.com/workers/wrangler/install-and-update/" target="_blank"> Install Wrangler </a>

Build your site with Jekyll (don’t run the Jekyll server for this step).  
Run the Pages emulator against the ```_site``` folder.  

```bash
# From your project root
bundle exec jekyll build

# Emulate Cloudflare Pages locally on port 8788, serving from the _site directory
wrangler pages dev _site

# Output will include a local URL like:
# Ready on http://localhost:8788
```

## Create a Cloudflare Pages project

- Sign in: <a href="https://developers.cloudflare.com/pages/" target="_blank"> Cloudflare Pages </a>
- Go to Workers & Pages.
- Create a new application and choose Upload Static Files.
- You’ll later connect your domain to the Pages project (custom domain).  
R2 is optional and useful when you want object storage (e.g., images or data) that you read via a Function or Worker.  
Prepare a ZIP for upload Zip everything inside ```_site``` and upload it as a deployment.

```bash
cd _site
zip -r ../myblog-site.zip *
```

## Deploy from the Pages dashboard

- Open your Pages app in the Cloudflare dashboard
- Click Create deployment.
- Upload the ZIP you created from ```_site```.
- Finish the deployment flow, then attach your custom domain to the Pages project.

## Add posts and republish

Jekyll looks for posts in ```_posts``` with a specific naming format and front matter.  
Add a Markdown file, rebuild, and upload a fresh ZIP.

```text
.
├── _config.yml
├── _includes
├── _layouts
├── _posts           # Your Markdown posts go here
├── _site            # Build output (don’t edit directly)
├── 404.html
├── about.markdown
├── assets
├── functions        # Optional: add Pages Functions here
├── Gemfile
├── Gemfile.lock
├── index.markdown
└── vendor
```

Post filenames must follow: ```YYYY-MM-DD-title.md```

```text
_posts/2026-01-02-serverless-blog.md
```

Each post needs front matter with layout, title, and date; categories are optional.  
The front matter looks like:

```text
---
layout: post
title:  A Serverless Blog For Free
date:   2025-12-27 14:49:48 -0600
categories: Programming
---
Your post content starts here as markdpwn content

```

## Where R2 fits in

For a basic blog, you can deploy entirely with Pages and never touch R2.  
Add R2 if you want:
- Large media or download storage
- A data bucket fetched at runtime by a Worker or Pages Function
- A place to push content from CI without egress charges to Cloudflare services

You can bind an R2 bucket to a Pages Function or Worker and fetch objects as needed.  
Keep static pages in Pages; put dynamic or large assets in R2.

## Wrap-up
That’s it: a cost-free, secure, and fast blog at the edge.  
You write Markdown, Jekyll builds static pages, and Cloudflare Pages serves them globally.  
If you later need dynamic features or storage, add a Pages Function and R2 without changing your basic deployment flow.  

Enjoy!