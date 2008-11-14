grammar URI::Grammar {
    #my($scheme, $authority, $path, $query, $fragment) =
    #$uri =~ m|(?:([^:/?#]+):)?
    #          (?://([^/?#]*))?
    #          ([^?#]*)
    #          (?:\?([^#]*))?
    #          (?:#(.*))?|;
    token TOP        { ^ <URI> $ };
    token URI        { [<scheme> ':']? [ '//' <authority>]? <path> ['?' <query>]? ['#' <fragment>]? };
    token scheme     { <-[:/&?#]>+ };
    token authority  { <-[/&?#]>* };
    token path       { '/'? [ <chunk> '/'?]+ };
    token chunk      { <-[/?#]>+ };
    token query      { <-[#]>* };
    token fragment   { .* };
}
