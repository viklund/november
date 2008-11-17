use v6;
class Dispatcher::Rule;

has $.name;
has @.tokens;

has @.args;
has $.way;

method is_applyable(@chunks) {
    #say ".is_applyable chunks:'~ @chunks;
    self.apply(@chunks, :try);
}

method apply (@chunks, $try?) {
    #say '.apply chunks:'~ @chunks ~ ' tokens:' ~ @.tokens;
    return False if @chunks != @.tokens;

    for @.tokens Z @chunks -> $token, $chunk {
        #say "t: $token, c:$chunk";
        if $chunk ~~ $token {
            @!args.push($/) if $/;
        }
        else {
            @!args = undef;
            return False;
        }
    }
    return True if $try;
 
    if @.args {
        # RAKUDO: | do not implemented yet, so only one param now
        $.way(@.args[0]);
    }
    else {
        $.way();
    }
}

method is_complite {
    if $.name && @.tokens && $.way {
        return True;
    }
    
    return False;
}

# vim:ft=perl6
