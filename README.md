# Configure Varnish Cache Based On The Cookies
Look up the cache based on the the language cookies
When we browse the multiple-language website, it will create the cookies like WebSiteLang=lang_short_name (for example WebSiteLang=es (spanish))
Based on the language, Varnish will cache and serve the cache.
This is used for Fastly using varnish 2.1.5. You can convert it to use for other versions of Varnish.
