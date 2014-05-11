class November::URI;

# This class used to be called just 'URI', but there was a collision with
# the eponymous class in the 'uri' project. Arguably, that class has more
# rights to that name, so this one was renamed. Since the 'uri' project
# ought to cover the same functionality as this class, maybe long-term we
# could switch to using that instead. One more dependency, but less code
# duplication across projects.

use November::URI::Grammar;
# RAKUDO: Match object does not do assignment properly :(
#my Match $.parts; dies in init with 'Type mismatch in assignment';
# workaround:
has $.uri;
has @.chunks;

submethod BUILD(:$uri) {

    # clear string before parsing
    my $c_str = $uri;
    $c_str .= subst(/^ \s* ['<' | '"'] /, '');
    $c_str .= subst(/ ['>' | '"'] \s* $/, '');

    November::URI::Grammar.parse($c_str);
    unless $/ { die "Could not parse URI: $uri" }

    $!uri = $/;
    @!chunks = @($<path><chunk>) || ('');
}

method scheme {
    my $s = $.uri<scheme> || '';
    # RAKUDO: return 1 if use ~ below die because can`t do lc on Math after
    return ~$s.lc;
}

method authority {
    my $a = $.uri<authority> || '';
    # RAKUDO: return 1 if use ~ below die because can`t do lc on Math after
    return ~$a.lc;
}

method host {
    #RAKUDO: $.uri<authority>[0]<host> return full <authority> now
    my $h = ~$.uri<authority><host>;
    return $h.lc || '';
}

method port {
    # TODO: send rakudobug
    # RAKUDO: $.uri<authority><port> return full <authority> now
    # workaround:
    item $.uri<authority><port> || '';
}

method path {
    my $p = ~$.uri<path> || '';
    return $p.lc;
}

method absolute {
    # RAKUDO: The grammar uses <slash>?, so this should be either Nil or a
    # Match object. But Rakudo returns [] or [Match] instead, so we must use
    # || instead of // to test.
    return ?($.uri<path><slash> || $.scheme);
}

method relative {
    # Rakudo: Must use || instead of //, see above.
    return !($.uri<path><slash> || $.scheme);
}

method query {
    item $.uri<query> || '';
}
method frag {
    my $f = $.uri<fragment> || '';
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

November::URI — Uniform Resource Identifiers (absolute and relative) 

=head SYNOPSYS

    use November::URI;
    my $u = November::URI.new;
    $u.init('http://example.com/foo/bar?tag=woow#bla');

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
