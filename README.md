# Configure Varnish Cache Based On The Cookies
Look up the cache based on the the language cookies
When we browse the multiple-language website, it will create the cookies like WebSiteLang=lang_short_name (for example WebSiteLang=es (spanish))
Based on the language, Varnish will cache and serve the cache.
This is used for Fastly using varnish 2.1.5. You can convert it to use for other versions of Varnish.

To make it work with Varnish 3.x and 4.x, you will have to convert something like:

Varnish 2.x: set req.hash += req.url;
Varnihs 3.x: hash_data(req.url);

So we will have:
    >hash_data(req.url);
    >if (req.http.host) {
    >    hash_data(req.http.host);
    >} else {
    >   hash_data(server.ip);
    >}
    >if (req.http.Cookie) {
    >    #add cookie in hash
    >    hash_data(req.http.Cookie);
    >}
	
For more information or need help, please contact me at knguyen@vincosolution.com.