unit class Dispatcher::Rule;
has @.pattern;
has @.args;

has Str $.controller is rw;
has Str $.action     is rw;

has Code $.code;

method match (@chunks) {
    return False if @chunks != @!pattern;
    # RAKUDO: Z seems to have a bug (fixed in nom), where [1,2] Z [*,*] yields (1, Any, 2, Any): the Whatever is lost
    #for @chunks Z @!pattern -> $chunk, $rule is copy {
    for ^@chunks -> $i {
        my $chunk = @chunks[$i];
        my $rule = @!pattern[$i];
        #note "- chunk ({$chunk.perl}), rule ({$rule.perl})";

        my $param;
        if $rule ~~ Pair { ($param, $rule) = $rule.kv }

        if ~$chunk ~~ $rule {
            if $param {
                self."$param"() = ~($/ // $chunk);
            } else {
                @!args.push($/ || $chunk) if $rule ~~ Regex | Whatever;
            }
        }
        else {
            self.clear;
            return False;
        }
    }
    return True;
}

method apply {
    # RAKUDO: die with FixedIntegerArray: index out of bounds! on test 01/3
    #$!code(| @!args, controller => $.controller, action => $.action );
    # workaround:
    if $!controller and $!action {
        $!code(| @!args, action => $.action, controller => $.controller );
    } elsif $!action {
        $!code(| @!args, action => $.action );
    } elsif $!controller {
        $!code(| @!args, controller => $.controller );
    } else {
        $!code(| @!args );
    }
}

method is_complete {
    return ?( @!pattern && $!code );
}

method clear {
    @!args = ();
    $!controller = Nil;
    $!action = Nil;
}

# vim:ft=perl6
