class URI;

# RAKUDO: Match object does not do assignment properly :(
#my Match $.parts; dies in init with 'Type mismatch in assignment';
# workaround:
has $.uri;
has @.chunks;

method init ($str) {
    use URI::Grammar;

    # clear string before parsing
    my $c_str = $str;
    $c_str .= subst(/^ \s* ['<' | '"'] /, '');
    $c_str .= subst(/ ['>' | '"'] \s* $/, '');

    URI::Grammar.parse($c_str);
    unless $/ { die "Could not parse URI: $str" }

    $!uri = $/;
    @!chunks = $/<path><chunk> // ('');
}

method scheme {
    my $s = $.uri<scheme> // '';
    # RAKUDO: return 1 if use ~ below die because can`t do lc on Math after
    return ~$s.lc;
}

method authority {
    my $a = $.uri<authority> // '';
    # RAKUDO: return 1 if use ~ below die because can`t do lc on Math after
    return ~$a.lc;
}

method host {
    #RAKUDO: $.uri<authority>[0]<host> return full <authority> now
    my $h = ~$.uri<authority>[0]<host>;
    return $h.lc // '';
}

method port {
    # TODO: send rakudobug
    # RAKUDO: $.uri<authority><port> return full <authority> now
    # workaround:
    item $.uri<authority>[0]<port> // '';
}

method path {
    my $p = ~$.uri<path> // '';
    return $p.lc;
}

method absolute {
    return ?($.uri<path><slash> // $.scheme);
}

method relative {
    return !($.uri<path><slash> // $.scheme);
}

method query {
    item $.uri<query> // '';
}
method frag {
    my $f = $.uri<fragment> // '';
    return ~$f.lc;
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

=head NAME

URI — Uniform Resource Identifiers (absolute and relative) 

=head SYNOPSYS

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
