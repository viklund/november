class Dispatcher::Rule;
has @.tokens;
has @.args;
has $.action;

method match (@chunks) {
    return False if @chunks != @.tokens;
    for @chunks Z @.tokens-> $chunk, Object $token {
        if ~$chunk ~~ $token {
            @!args.push($/) if $/;
            @!args.push(~$chunk) if $token ~~ Whatever;
        }
        else {
            self.clear;
            return False;
        }
    }
    return True;
}

method apply {
    $!action(| @!args);
}

method is_complete {
    return ?( @!tokens && $!action );
}

method clear {
    @!args = ();
}

# vim:ft=perl6
