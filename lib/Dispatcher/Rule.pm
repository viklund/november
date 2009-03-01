class Dispatcher::Rule;
has @.tokens;
has @.args;
has $.action;

method match (@chunks) {
    return False if @chunks != @.tokens;
    for @chunks Z @.tokens-> Str $chunk, Object $token {
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
        $.action(@.args[0]);

        # RAKUDO: strange bug here, it assigns 0 when ifs are nested
        #$.action(@.args[0]) if @.args == 1;
        #$.action(@.args[0], @.args[1]) if @.args == 2;
        #$.action(@.args[0], @.args[1], @.args[2]) if @.args == 3;
    }
    elsif @.args == 2 {
            $.action(@.args[0], @.args[1]);
    }
    else {
        $.action();
    }
}

method is_complete {
    return ?( @.tokens && $.action );
}

method clear {
    @!args = ();
}

# vim:ft=perl6
