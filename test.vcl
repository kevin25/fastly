sub vcl_recv {
  #FASTLY recv
    if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
      return(pass);
    }
    if (req.url ~ "en" || req.url ~ "^/$") {

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
    return(lookup);

}
sub vcl_fetch {
  #FASTLY fetch

    if (beresp.http.Vary) {
        set beresp.http.Vary = beresp.http.Vary ", MyLang";
      } else {
        set beresp.http.Vary = "MyLang";
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

}
sub vcl_hash {
  #FASTLY hash
    set req.hash += req.url;
    if (req.http.host) {
    set req.hash += req.http.host;
        #hash_data(req.http.host);
    } else {
    set req.hash += server.ip;
        #hash_data(server.ip);
    }
    if (req.http.Cookie) {
        #add cookie in hash
    set req.hash += req.http.Cookie;
        #hash_data(req.http.Cookie);
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
