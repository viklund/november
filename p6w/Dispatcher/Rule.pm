use v6;
class Dispatcher::Rule;

has $.name;
# RAKUDO: can`t set attr-array in new
has @.tokens is rw;

has @.args;
has $.way;

method is_applyable(@chunks) {
    self.apply(@chunks, :try);
}

method apply (@chunks, $try?) {

    return False if @chunks != @.tokens;

    for @.tokens Z @chunks -> $token, $chunk {
        if $chunk ~~ $token {
            @!args.push($/) if $/;
        }
        else {
            $!arg = undef;
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
