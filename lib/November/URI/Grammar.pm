use v6;
grammar November::URI::Grammar {
    token TOP        { ^ [<scheme> ':']? [ '//' <authority>]? <path> ['?' <query>]? ['#' <fragment>]? $ };
    token scheme     { <-[:/&?#]>+ };
    token authority  { <host> [':' <port>]? };
    token host       { <-[/&?#:]>* };
    token port       { (\d**1..5) 
                        <?{ $0 < 2 ** 16 }>
                       <!before \d> };
    token path       { <slash>? [ <chunk> '/'?]* }; # * mb wrong, because that allow '' URI
    token slash      { '/' };
    token chunk      { <-[/?#]>+ };
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
