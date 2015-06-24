sub vcl_recv {

    if (req.http.Cookie ~ "WebSiteLang=") {
            #unset all the cookie from request except language
        set req.http.Language = regsub(req.http.Cookie, "(?:^|;\s*)(?:WebSiteLang=(.*?))(?:;|$)", "\1.");
        } elseif (!req.http.Cookie) {
            set req.http.Language = "deleted";
        }

        if (req.url ~ "en") {

        set req.http.MyLang = "MyLang=deleted";

        } elseif (req.url ~ "ja") {

        set req.http.MyLang = "MyLang=ja";

        } elseif (req.url ~ "es") {

        set req.http.MyLang = "MyLang=es";

        } elseif (req.url ~ "it") {

        set req.http.MyLang = "MyLang=it";

        } elseif (req.url ~ "de") {

        set req.http.MyLang = "MyLang=de";

        } elseif (req.url ~ "pt") {

        set req.http.MyLang = "MyLang=pt";

        } elseif (req.url ~ "fr") {

        set req.http.MyLang = "MyLang=fr";

        }
    # Forward client's IP to backend
    remove req.http.X-Forwarded-For;
    set req.http.X-Forwarded-For = client.ip;

    # Set the URI of your system directory
    if (req.url ~ "^/system/" ||
        req.url ~ "ACT=" ||
        req.request == "POST" ||
        (req.url ~ "member_box" && req.http.Cookie ~ "exp_sessionid"))
    {
        return (pass);
    }

    #unset req.http.Cookie;

    set req.grace = 1h;

    return(lookup);
}

sub vcl_fetch {

   #if (!beresp.http.set-Cookie ~ "WebSiteLang="){
   #     unset beresp.http.set-cookie;
   #}

    # Enable ESI includes
    #set beresp.do_esi = true;

    # Our cache TTL
    if (beresp.http.Vary) {
        set beresp.http.Vary = beresp.http.Vary ", MyLang";
      } else {
        set beresp.http.Vary = "MyLang";
    }
    set beresp.ttl = 10m;

    set beresp.grace = 1h;

    return(deliver);

}

sub vcl_deliver {
    
    #if (req.http.X-Varnish-Accept-Language) {
    #    set resp.http.Set-Cookie = req.http.Language;
    #}
    if (resp.http.Vary) {
       set resp.http.Vary = regsub(resp.http.Vary, "MyLang", "WebSiteLang");
       set resp.http.Set-Cookie = req.http.MyLang;
  }
    if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
}