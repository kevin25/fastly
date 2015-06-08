sub vcl_recv {
  #FASTLY recv
	#if (req.url ~ "\.[a-z]") {
	#		set req.http.url.Language = "WebSiteLang=[a-z]";		
	#}

    if (req.url ~ "en") {
        set req.http.url.Language = "WebSiteLang=en";
    } elseif (req.url ~ "ja") {
        set req.http.url.Language = "WebSiteLang=ja";
    } elseif (req.url ~ "es") {
        set req.http.url.Language = "WebSiteLang=es";
    } elseif (req.url ~ "it") {
        set req.http.url.Language = "WebSiteLang=it";
    } elseif (req.url ~ "de") {
        set req.http.url.Language = "WebSiteLang=de";
    } elseif (req.url ~ "pt") {
        set req.http.url.Language = "WebSiteLang=pt";
    } elseif (req.url ~ "fr") {
        set req.http.url.Language = "WebSiteLang=fr";
    }
}
sub vcl_fetch {
	#FASTLY fetch
	if (!req.http.Language){
		set req.http.Language = req.http.url.Language;
	}
    set beresp.do_esi = true;
    # Our cache TTL
    set beresp.ttl = 15m;
    set beresp.grace = 1h;
    return(deliver);
    # Header rewrite Remove Headers : 10
    #unset beresp.http.Set-Cookie;

}
sub vcl_deliver {
	#FASTLY deliver
    if (req.http.Language) {
        set resp.http.Set-Cookie = req.http.url.Language;
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
    if (req.http.Language) {
        #add cookie in hash
		set req.hash += req.http.Language;
        #hash_data(req.http.Language);
    }
    return(hash);
}
