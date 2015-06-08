sub vcl_recv {
  #FASTLY recv
    if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
      return(pass);
    }
   if (req.http.Cookie ~ "WebSiteLang=") {
    set req.http.MyLang = req.http.Cookie;
    unset req.http.Cookie;
   }
    return(lookup);

}
sub vcl_fetch {
	#FASTLY fetch

    if (beresp.http.Vary) {
        set beresp.http.Vary = beresp.http.Vary ", MyLang";
      } else {
        set beresp.http.Vary = "MyLang";
    }
    if (beresp.http.Set-Cookie) {
      set req.http.MyLang = beresp.http.Set-Cookie;
      unset beresp.http.Set-Cookie;
    }
      if ((beresp.status == 500 || beresp.status == 503) && req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
    restart;
  }

  if(req.restarts > 0 ) {
    set beresp.http.Fastly-Restarts = req.restarts;
  }

  if (beresp.http.Set-Cookie) {
    set req.http.Fastly-Cachetype = "SETCOOKIE";
    return (pass);
  }

  if (beresp.http.Cache-Control ~ "private") {
    set req.http.Fastly-Cachetype = "PRIVATE";
    return (pass);
  }

  if (beresp.status == 500 || beresp.status == 503) {
    set req.http.Fastly-Cachetype = "ERROR";
    set beresp.ttl = 1s;
    set beresp.grace = 5s;
    return (deliver);
  }

  if (beresp.http.Expires || beresp.http.Surrogate-Control ~ "max-age" || beresp.http.Cache-Control ~"(s-maxage|max-age)") {
    # keep the ttl here
  } else {
    # apply the default ttl
    set beresp.ttl = 3600s;
  }
  return(deliver);

}
sub vcl_deliver {
	#FASTLY deliver
   if (resp.http.Vary) {
    set resp.http.Vary = regsub(resp.http.Vary, "MyLang", "WebSiteLang");
  } 
  if (req.url ~ "ja" && req.http.Cookie !~ "WebSiteLang=ja") { 
    add resp.http.Set-Cookie = "WebSiteLang=ja; expires=" now + 180d "; path=/;";
  } 
  if (req.url ~ "es" && req.http.Cookie !~ "WebSiteLang=es") { 
    add resp.http.Set-Cookie = "WebSiteLang=es; expires=" now + 180d "; path=/;";
  }
  if (req.url ~ "pt" && req.http.Cookie !~ "WebSiteLang=pt") { 
    add resp.http.Set-Cookie = "WebSiteLang=pt; expires=" now + 180d "; path=/;";
  } 
  if (req.url ~ "it" && req.http.Cookie !~ "WebSiteLang=it") { 
    add resp.http.Set-Cookie = "WebSiteLang=it; expires=" now + 180d "; path=/;";
  }  
  if (req.url ~ "fr" && req.http.Cookie !~ "WebSiteLang=fr") { 
    add resp.http.Set-Cookie = "WebSiteLang=fr; expires=" now + 180d "; path=/;";
  } 
  if (req.url ~ "de" && req.http.Cookie !~ "WebSiteLang=de") { 
    add resp.http.Set-Cookie = "WebSiteLang=de; expires=" now + 180d "; path=/;";
  }
  if (req.url ~ "en" && req.http.Cookie !~ "WebSiteLang=en") { 
    add resp.http.Set-Cookie = "WebSiteLang=en; expires=" now + 180d "; path=/;";
  }
  if (req.http.MyLang) {
    set resp.http.Set-Cookie = req.http.MyLang;
  }
}
sub vcl_hash {
  #FASTLY hash
    if(req.http.WebSiteLang) {
      set req.hash += req.http.WebSiteLang;
    }
    return(hash);
}
sub vcl_hit {
#FASTLY hit

  if (!obj.cacheable) {
    return(pass);
  }
  return(deliver);
}

sub vcl_miss {
#FASTLY miss
  return(fetch);
}
sub vcl_error {
#FASTLY error
}

sub vcl_pass {
#FASTLY pass
}
