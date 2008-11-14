use v6;

class URI;

# RAKUDO: Match object do not assign clear :(
#my Match $.parts; dies in init with Type mismatch in assignment;
# workaround:
has $.uri;
has @.chunks;

method init ($str) {
    use URI::Grammar;
    $str ~~ URI::Grammar::TOP;
    unless $/ { die "Could not parse URI: $str" }

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
    #RAKUDO: $.uri<authority> return 1, and than we try 1<port> and die :( 
    #$.uri<authority><host>;
    # workaround:
    my %p = $.uri<authority>;
    my $h =  %p<host> // '';
    return $h.lc;
}

method port {
    #RAKUDO: $.uri<authority> return 1, and than try 1<port> and die :( 
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

=begin pod

=haed NAME

URI — Uniform Resource Identifiers (absolute and relative) 

=haed SYNOPSYS

    use URI;
    my $u = URI.new;
    $u.init('http://her.com/foo/bar?tag=woow#bla');

    my $scheme = $u.scheme;
    my $authority = $u.authority;
    my $host = $u.host;
    my $port = $u.port;
    my $path = $u.path;
    my $query = $u.query;
    my $frag = $u.frag; # or $u.fragment;

    my $is_absolute = $u.absolute;
    my $is_relative = $u.relative;

=end pod


# vim:ft=perl6
