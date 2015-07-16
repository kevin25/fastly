sub vcl_recv {

   set req.http.Lang = req.http.Cookie:siteLang;


#FASTLY recv

if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
      return(pass);
    }

    return(lookup);

}

sub vcl_fetch {

  if (beresp.http.Set-Cookie){
  # The response has a Set-Cookie ...
    set beresp.http.Lang-Set-Cookie = beresp.http.Set-Cookie;
    unset beresp.http.Set-Cookie;
  }

  set beresp.http.Vary = "Lang";

  #For Debugging Purposes
  set beresp.http.X-Lang = req.http.Cookie:siteLang;




#FASTLY fetch

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
    set beresp.ttl = 31536000s;
  }

  return(deliver);

}

sub vcl_deliver {


#FASTLY deliver

  set resp.http.Set-Cookie = resp.http.Lang-Set-Cookie;
  unset resp.http.Lang-Set-Cookie;
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