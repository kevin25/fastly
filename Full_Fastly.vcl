C!
# Backends

backend default_backend {
    .first_byte_timeout = 15s;
    .connect_timeout = 1s;
    .max_connections = 200;
    .between_bytes_timeout = 10s;
    .share_key = "your key";
    .port = "80";
    .host = "Your Ip";
  
      
  
}



sub vcl_recv {
#--FASTLY RECV CODE START
  if (req.restarts == 0) {
    if (!req.http.X-Timer) {
      set req.http.X-Timer = "S" time.start.sec "." time.start.usec_frac;
    }
    set req.http.X-Timer = req.http.X-Timer ",VS0";
  }

            

    
  # default conditions
  set req.backend = default_backend;
  

  
  # end default conditions

  
      
  
#--FASTLY RECV CODE END
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



#--FASTLY FETCH START


# record which cache ran vcl_fetch for this object and when
  set beresp.http.Fastly-Debug-Path = "(F " server.identity " " now.sec ") " if(beresp.http.Fastly-Debug-Path, beresp.http.Fastly-Debug-Path, "");

# generic mechanism to vary on something
  if (req.http.Fastly-Vary-String) {
    if (beresp.http.Vary) {
      set beresp.http.Vary = "Fastly-Vary-String, "  beresp.http.Vary;
    } else {
      set beresp.http.Vary = "Fastly-Vary-String, ";
    }
  }
  
    
  
 # priority: 0

 
      
  # Header rewrite Remove Headers : 10
  
      
            unset beresp.http.Set-Cookie;
          
  
 
 
      
#--FASTLY FETCH END


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


#--FASTLY DELIVER START

# record the journey of the object, expose it only if req.http.Fastly-Debug.
  if (req.http.Fastly-Debug || req.http.Fastly-FF) {
    set resp.http.Fastly-Debug-Path = "(D " server.identity " " now.sec ") "
       if(resp.http.Fastly-Debug-Path, resp.http.Fastly-Debug-Path, "");

    set resp.http.Fastly-Debug-TTL = if(obj.hits > 0, "(H ", "(M ")
       server.identity
       if(req.http.Fastly-Tmp-Obj-TTL && req.http.Fastly-Tmp-Obj-Grace, " " req.http.Fastly-Tmp-Obj-TTL " " req.http.Fastly-Tmp-Obj-Grace " ", " - - ")
       if(resp.http.Age, resp.http.Age, "-")
       ") "
       if(resp.http.Fastly-Debug-TTL, resp.http.Fastly-Debug-TTL, "");
  } else {
    unset resp.http.Fastly-Debug-Path;
    unset resp.http.Fastly-Debug-TTL;
  }

  # add or append X-Served-By/X-Cache(-Hits)
  {

    if(!resp.http.X-Served-By) {
      set resp.http.X-Served-By  = server.identity;
    } else {
      set resp.http.X-Served-By = resp.http.X-Served-By ", " server.identity;
    }

    set resp.http.X-Cache = if(resp.http.X-Cache, resp.http.X-Cache ", ","") if(fastly_info.state ~ "HIT($|-)", "HIT", "MISS");

    if(!resp.http.X-Cache-Hits) {
      set resp.http.X-Cache-Hits = obj.hits;
    } else {
      set resp.http.X-Cache-Hits = resp.http.X-Cache-Hits ", " obj.hits;
    }

  }

  if (req.http.X-Timer) {
    set resp.http.X-Timer = req.http.X-Timer ",VE" time.elapsed.msec;
  }

  # VARY FIXUP
  {
    # remove before sending to client
    set resp.http.Vary = regsub(resp.http.Vary, "Fastly-Vary-String, ", "");
    if (resp.http.Vary ~ "^\s*$") {
      unset resp.http.Vary;
    }
  }
  unset resp.http.X-Varnish;


  # Pop the surrogate headers into the request object so we can reference them later
  set req.http.Surrogate-Key = resp.http.Surrogate-Key;
  set req.http.Surrogate-Control = resp.http.Surrogate-Control;

  # If we are not forwarding or debugging unset the surrogate headers so they are not present in the response
  if (!req.http.Fastly-FF && !req.http.Fastly-Debug) {
    unset resp.http.Surrogate-Key;
    unset resp.http.Surrogate-Control;
  }

  if(resp.status == 550) {
    return(deliver);
  }
  

  #default response conditions
    
  
      

  
#--FASTLY DELIVER END
   if (resp.http.Vary) {
    set resp.http.Vary = regsub(resp.http.Vary, "X-Language", "WebSiteLang");
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
    add resp.http.Set-Cookie = "WebSiteLang=deleted; expires=" now + 180d "; path=/;";
  }
}
sub vcl_hash {

#--FASTLY HASH start
  # support purge all
  set req.hash += "#####GENERATION#####";
#--FASTLY HASH end
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
        #hash_data(req.http.Language);
    }
    return(hash);
}
sub vcl_hit {
#--FASTLY HIT START

# we cannot reach obj.ttl and obj.grace in vcl_deliver, save them when we can in vcl_hit
  set req.http.Fastly-Tmp-Obj-TTL = obj.ttl;
  set req.http.Fastly-Tmp-Obj-Grace = obj.grace;

  {
    set req.http.Fastly-Cachetype = "HIT";

    
  }
#--FASTLY HIT END

  if (!obj.cacheable) {
    return(pass);
  }
  return(deliver);
}

sub vcl_miss {
#--FASTLY MISS START

# this is not a hit after all, clean up these set in vcl_hit
  unset req.http.Fastly-Tmp-Obj-TTL;
  unset req.http.Fastly-Tmp-Obj-Grace;

  {
    if (req.http.Fastly-Check-SHA1) {
       error 550 "Doesnt exist";
    }
    
#--FASTLY BEREQ START
    {
      if (req.http.Fastly-Original-Cookie) {
        set bereq.http.Cookie = req.http.Fastly-Original-Cookie;
      }
      
      if (req.http.Fastly-Original-URL) {
        set bereq.url = req.http.Fastly-Original-URL;
      }
      {
        if (req.http.Fastly-FF) {
          set bereq.http.Fastly-Client = "1";
        }
      }
      {
        # do not send this to the backend
        unset bereq.http.Fastly-Original-Cookie;
        unset bereq.http.Fastly-Original-URL;
        unset bereq.http.Fastly-Vary-String;
        unset bereq.http.X-Varnish-Client;
      }
      if (req.http.Fastly-Temp-XFF) {
         if (req.http.Fastly-Temp-XFF == "") {
           unset bereq.http.X-Forwarded-For;
         } else {
           set bereq.http.X-Forwarded-For = req.http.Fastly-Temp-XFF;
         }
         # unset bereq.http.Fastly-Temp-XFF;
      }
    }
#--FASTLY BEREQ STOP


 #;

    set req.http.Fastly-Cachetype = "MISS";

    
  }
#--FASTLY MISS STOP
  return(fetch);
}
sub vcl_error {
#--FASTLY ERROR START

  if (obj.status == 801) {
     set obj.status = 301;
     set obj.response = "Moved Permanently";
     set obj.http.Location = "https://" req.http.host req.url;
     synthetic {""};
     return (deliver);
  }

  
      
  if (req.http.Fastly-Restart-On-Error) {
    if (obj.status == 503 && req.restarts == 0) {
      restart;
    }
  }

  {
    if (obj.status == 550) {
      return(deliver);
    }
  }
#--FASTLY ERROR END


}

sub vcl_pass {
#--FASTLY PASS START
  {
    
#--FASTLY BEREQ START
    {
      if (req.http.Fastly-Original-Cookie) {
        set bereq.http.Cookie = req.http.Fastly-Original-Cookie;
      }
      
      if (req.http.Fastly-Original-URL) {
        set bereq.url = req.http.Fastly-Original-URL;
      }
      {
        if (req.http.Fastly-FF) {
          set bereq.http.Fastly-Client = "1";
        }
      }
      {
        # do not send this to the backend
        unset bereq.http.Fastly-Original-Cookie;
        unset bereq.http.Fastly-Original-URL;
        unset bereq.http.Fastly-Vary-String;
        unset bereq.http.X-Varnish-Client;
      }
      if (req.http.Fastly-Temp-XFF) {
         if (req.http.Fastly-Temp-XFF == "") {
           unset bereq.http.X-Forwarded-For;
         } else {
           set bereq.http.X-Forwarded-For = req.http.Fastly-Temp-XFF;
         }
         # unset bereq.http.Fastly-Temp-XFF;
      }
    }
#--FASTLY BEREQ STOP


 #;
    set req.http.Fastly-Cachetype = "PASS";
  }
#--FASTLY PASS STOP
}

sub vcl_pipe {
#--FASTLY PIPE START
  {
    #  error 403 "Forbidden";      
    
#--FASTLY BEREQ START
    {
      if (req.http.Fastly-Original-Cookie) {
        set bereq.http.Cookie = req.http.Fastly-Original-Cookie;
      }
      
      if (req.http.Fastly-Original-URL) {
        set bereq.url = req.http.Fastly-Original-URL;
      }
      {
        if (req.http.Fastly-FF) {
          set bereq.http.Fastly-Client = "1";
        }
      }
      {
        # do not send this to the backend
        unset bereq.http.Fastly-Original-Cookie;
        unset bereq.http.Fastly-Original-URL;
        unset bereq.http.Fastly-Vary-String;
        unset bereq.http.X-Varnish-Client;
      }
      if (req.http.Fastly-Temp-XFF) {
         if (req.http.Fastly-Temp-XFF == "") {
           unset bereq.http.X-Forwarded-For;
         } else {
           set bereq.http.X-Forwarded-For = req.http.Fastly-Temp-XFF;
         }
         # unset bereq.http.Fastly-Temp-XFF;
      }
    }
#--FASTLY BEREQ STOP


    #;
    set req.http.Fastly-Cachetype = "PIPE";
    set bereq.http.connection = "close";
  }
#--FASTLY PIPE STOP

}
