sub vcl_recv {
  if (req.http.Cookie ~ "WebSiteLang=") {
    # The request does have a tracking cookie so store it temporarily
    set req.http.Lang-Set-Cookie = req.http.Cookie;
    unset req.http.Cookie;
  } if (req.url ~ "pt")  {
     set req.http.Lang-Set-Cookie = "WebSiteLang=pt; expires=" now + 180d "; Max-Age=31536000;";
  }

#FASTLY recv
}

sub vcl_fetch {
  # The response has a Set-Cookie ...
  if (beresp.http.Set-Cookie) {
    # ... so store it temporarily
    set req.http.Lang-Set-Cookie = beresp.http.Set-Cookie;
    # ... and then unset it
    unset beresp.http.Set-Cookie;
  }

#FASTLY fetch
}

sub vcl_deliver {
  # Send the Cookie header again if we have it
  if (req.http.Lang-Set-Cookie) {
    set resp.http.Set-Cookie = req.http.Lang-Set-Cookie;
  }
  #if (req.url ~ "pt" || resp.http.Set-Cookie ~ "WebSiteLang=pt") {
  #  add resp.http.Set-Cookie = "WebSiteLang=pt; expires=" now + 180d "; Max-Age=31536000;";
  #}
  #if (req.url ~ "es" || resp.http.Set-Cookie ~ "WebSiteLang=es") {
  #  add resp.http.Set-Cookie = "WebSiteLang=es; expires=" now + 180d "; Max-Age=31536000;";
  #}
#FASTLY deliver
}