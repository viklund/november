use v6;
class Dispatcher::Rule;

has @.tokens;
has @.args;
has $.way;

method match (@chunks) {
    return False if @chunks != @.tokens;

    for @.tokens Z @chunks -> $token, $chunk {
        if ~$chunk ~~ $token {
            @!args.push($/) if $/;
        }
        else {
            self.clear;
            return False;
        }
    }
    return True;
}

method apply {
    # RAKUDO: | do not implemented yet :( so... only two args now
    # RAKUDO: strange bug here, it assigns 0 when ifs are nested
    #if @.args {
    if @.args == 1 {
        $.way(@.args[0]);

        # RAKUDO: strange bug here, it assigns 0 when ifs are nested
        #$.way(@.args[0]) if @.args == 1;
        #$.way(@.args[0], @.args[1]) if @.args == 2;
        #$.way(@.args[0], @.args[1], @.args[2]) if @.args == 3;
    }
    elsif @.args == 2 {
            $.way(@.args[0], @.args[1]);
    }
    else {
        $.way();
    }
}

method is_complete {
    return ?( @.tokens && $.way );
}

method clear {
    @!args = ();
}

# vim:ft=perl6
