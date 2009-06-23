use v6;
use Test;

class Test::InputOutput {
    has $.filter;

    method using($filter) {
        return Test::InputOutput.new( filter => $filter );
    }

    method test(@tests) {
        for @tests -> $test {
            my ($input, $expected, $description);

            if $test[0] ~~ Pair {
                $input       = $test[0].key;
                $expected    = $test[0].value;
                $description = $test[1] // '';
            }
            else {
                if $test.elems < 2 {
                    ok(0);
                    return ();
                }
                $input, $expected, $description = $test.values;
            }

            my $actual = $!filter($input);

            is( $actual, $expected, $description );
        }
    }
}

# vim:ft=perl6
