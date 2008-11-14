grammar URI::Grammar {
    #my($scheme, $authority, $path, $query, $fragment) =
    #$uri =~ m|(?:([^:/?#]+):)?
    #          (?://([^/?#]*))?
    #          ([^?#]*)
    #          (?:\?([^#]*))?
    #          (?:#(.*))?|;
    token TOP        { ^ [<scheme> ':']? [ '//' <authority>]? <path> ['?' <query>]? ['#' <fragment>]? $ };
    token scheme     { <-[:/&?#]>+ };
    token authority  { <host> [':' <port>]? };
    token host       { <-[/&?#:]>* };
    token port       { \d+ };
    token path       { <slash>? [ <chunk> '/'?]* }; # * here mb wrong, because that allow '' URI
    token slash      { '/' };
    token chunk      { <-[/?#]>+ };
    token query      { <-[#]>* };
    token fragment   { .* };
}
