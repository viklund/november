use v6;
grammar November::URI::Grammar {
    token TOP        { ^ [<scheme> ':']? [ '//' <authority>]? <path> ['?' <query>]? ['#' <fragment>]? $ };
    token scheme     { <-[:/&?#]>+ };
    token authority  { <host> [':' <port>]? };
    token host       { <-[/&?#:]>* };
    token port       { (\d**1..5) 
                        <?{{ $I0 = match[0]
                             $I1 = 0
                             if $I0 > 65535 goto fail
                             $I1 = 1
                           fail:
                             .return ($I1)
                        }}>
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
