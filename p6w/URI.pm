use v6;

class URI;

# RAKUDO: Cant assign Match object :(
#my Match $.parts;
# workaround:
my $.parts = {};
has @.chunks;

method init ($str) {
    use URI::Grammar;
    $str ~~ URI::Grammar::TOP;
    unless $/ { die "Could not parse URI: $str" }

    # RAKUDO: Cant assign Match object :(
    #$.parts = $/<URI>;

    $.parts<scheme>    = $/<URI><scheme>;
    $.parts<authority> = $/<URI><authority>;
    $.parts<path>      = ~$/<URI><path>;
    $.parts<query>     = $/<URI><query>;
    $.parts<fragment>  = $/<URI><fragment>;
    @!chunks = $/<URI><path><chunk>.values;
}

method scheme {
    return  ~$.parts<scheme>.lc;
}

method host {
    ~$.parts<authority> ~~ m/ <-[/:]>+ /;
    return $/.lc;
}

method port {
    ~$.parts<authority> ~~ m/ <.after ':'> \d+ $/;
    return $/
}

method path {
    ~$.parts<path>.lc;
}

method query {
    ~$.parts<query>;
}
method frag {
    ~$.parts<fragment>.lc;
}

method Str() {
    return 
        $.parts<scheme> ~ 
        '://' ~ $.parts<authority> ~ 
         ~ $.parts<path> ~
        '?' ~ $.parts<query> ~
        '#' ~ $.parts<fragment>;
}

# vim:ft=perl6
