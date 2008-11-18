use v6;
class Dispatcher::Rule;

has @.tokens;
has @.args;
has $.way;

method match (@chunks) {
    #say 'match chunks:'~ @chunks.elems ~ ' tokens:' ~ @.tokens.elems;
    return False if @chunks != @.tokens;

    for @.tokens Z @chunks -> $token, $chunk {
        #say "t: $token, c:$chunk";
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
    #say "args: { @.args.elems }";
    # RAKUDO: | do not implemented yet :( so... only two args now
    # RAKUDO: strange bug here, assign 0 there if I nested ifs
    #if @.args {
    if @.args == 1 {
        $.way(@.args[0]);

        # RAKUDO: strange bug here, assign 0 there if I nested ifs
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

method is_complite {
    if @.tokens && $.way { return True }
    return False;
}

method clear {
    @!args = ();
}

# vim:ft=perl6
