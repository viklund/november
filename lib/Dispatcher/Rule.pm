class Dispatcher::Rule;
has @.pattern;
has @.args;

has $.controller;
has $.action;


method match (@chunks) {
    return False if @chunks != @!pattern;
    for @chunks Z @!pattern-> $chunk, Object $rule {

        my $param;
        if $rule ~~ Pair { ($param, $rule) = $rule.kv }

        if ~$chunk ~~ $rule {
            # RAKUDO: /./ ~~ Regex us false, but /./ ~~ Code is true  
            @!args.push($/ || $chunk) if $rule ~~ Code | Whatever; # should by Regex | Whatever
            self.$param($/ || $chunk) if $param;
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
    return ?( @!pattern && $!action );
}

method clear {
    @!args = ();
}

# vim:ft=perl6
