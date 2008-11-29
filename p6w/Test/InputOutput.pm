use v6;
use Test;

class Test::InputOutput {
    has &.filter;

    method using(&filter) {
        return Test::InputOutput.new( filter => &filter );
    }

    method test(@tests) {
        for @tests -> $test {
            my $input       = $test[0];
            my $expected    = $test[1];
            my $description = $test[2];

            my $actual = &.filter($input);

            is( $expected, $actual, $description );
        }
    }
}

# vim:ft=perl6
