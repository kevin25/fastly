sub vcl_recv {
    #FASTLY recv

    if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
      return(pass);
    }
       if (req.url ~ "en") {
        set req.http.MyLang = "MyLang=en";
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
        if (req.http.MyLang) {
            set req.http.Language = regsub(req.http.Language, "MyLang", "WebSiteLang" );
        }
        if (req.url ~ "pt") {
                set req.http.host = "dev.onlinevideoconverter.com";
                set req.url = regsub(req.url, "^/$", "/pt");
        }


    return(lookup);


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
    # Deleted after receiving the backend
    #remove beresp.http.Set-Cookie;
    #remove beresp.http.Cookie;


}

sub vcl_deliver {
    #Deleted before sending the client
        remove resp.http.Cookie;
           if (resp.http.Vary) {
              set resp.http.Vary = regsub(resp.http.Vary, "MyLang", "WebSiteLang");
            } 
        if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
}
