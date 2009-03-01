use v6;
grammar URI::Grammar {
    token TOP        { ^ [<scheme> ':']? [ '//' <authority>]? <path> ['?' <query>]? ['#' <fragment>]? $ };
    token scheme     { <-[:/&?#]>+ };
    token authority  { <host> [':' <port>]? };
    token host       { <-[/&?#:]>* };
    token port       { \d+ };
    token path       { <slash>? [ <chunk> '/'?]* }; # * mb wrong, because that allow '' URI
    token slash      { '/' };
    token chunk      { <-[/?#:]>+ };
    token query      { <-[#]>* };
    token fragment   { .* };
}

# Official regexp (p5):
# my($scheme, $authority, $path, $query, $fragment) =
# $uri =~ m/
#           (?:([^:/?#]+):)?
#           (?://([^/?#]*))?
#           ([^?#]*)
#           (?:\?([^#]*))?
#           (?:#(.*))?
#         /x;

# vim:ft=perl6
