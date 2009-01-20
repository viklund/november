use v6;
use Test;

class Test::InputOutput {
    has $.filter;

    method using($filter) {
        return Test::InputOutput.new( filter => $filter );
    }

    method test(@tests) {
        for @tests -> $test {
            my $input       = $test[0].key;
            my $expected    = $test[0].value;
            my $description = $test[1];

            my $actual = $.filter($input);

            is( $actual, $expected, $description );
        }
    }
}

# vim:ft=perl6
