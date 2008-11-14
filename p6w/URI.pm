use v6;

class URI;

# RAKUDO: Cant assign Match object :(
#my Match $.parts;
# workaround:
has $.uri;
has @.chunks;

method init ($str) {
    use URI::Grammar;
    $str ~~ URI::Grammar::TOP;
    unless $/ { die "Could not parse URI: $str" }

    # RAKUDO: Cant assign Match object :(
    $!uri = $/;

    @!chunks = $/<path><chunk>;
}

method scheme {
    my $s = $.uri<scheme> // '';
    return $s.lc;
}

method authority {
    my $a = $.uri<authority> // '';
    return $a.lc;
}

method host {
    #RAKUDO: $.uri<authority> return 1, and that try 1<port> and die :( 
    #$.uri<authority><host>;
    # workaround:
    my %p = $.uri<authority>;
    my $h =  %p<host> // '';
    return $h.lc;
}

method port {
    #RAKUDO: $.uri<authority> return 1, and that try 1<port> and die :( 
    #$.uri<authority><port>;
    # workaround:
    my %p = $.uri<authority>;
    my $p = %p<port> // '';
    return $p;
}

method path {
    my $p = $.uri<path> // '';
    return $p.lc;
}

method absolute {
    my %p = $.uri<path>;
    ? (%p<slash> // 0);
}

method relative {
    my %p = $.uri<path>;
    ! (%p<slash> // 0);
}

method query {
    item $.uri<query> // '';
}
method frag {
    my $f = $.uri<fragment> // '';
    return $f.lc;
}

method fragment { $.frag }

method Str() {
    my $str;
    $str ~= $.scheme if $.scheme;
    $str ~= '://' ~ $.authority if $.authority;
    $str ~= $.path;
    $str ~= '?' ~ $.query if $.query;
    $str ~= '#' ~ $.frag if $.frag;
    return $str; 
}

# vim:ft=perl6
