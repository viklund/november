use v6;
grammar URI::Grammar {
    token TOP        { ^ [<scheme> ':']? [ '//' <authority>]? <path> ['?' <query>]? ['#' <fragment>]? $ };
    token scheme     { <-[:/&?#]>+ };
    token authority  { <host> [':' <port>]? };
    token host       { <-[/&?#:]>* };
    token port       { <pt6553X>|<pt655XX>|<pt65XXX>|<pt6XXXX>|<pt10K>|<ptLow> };
    token ptLow      { \d**1..4 };
    token pt10K      { <[1..5]>\d**4 };
    token pt6XXXX    { 6<[0..4]>\d**3 };
    token pt65XXX    { 65<[0..4]>\d**2 };
    token pt655XX    { 655<[0..2]>\d };
    token pt6553X    { 6553<[0..5]> };
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
