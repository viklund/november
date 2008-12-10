use v6;

use Text::Escape;
use HTML::Template::Grammar;

class HTML::Template {
    has $.input;
    has %!params;

    method from_string( Str $input ) {
        return self.new(input => $input);
    }

    method from_file($file_path) {
        return self.from_string( slurp($file_path) );
    }

    method param( Pair $param ) {
        %!params{$param.key} = $param.value;
    }

    method with_params( Hash %params ) {
        %!params = %params;
        return self;
    }

    method output() {
        return substitute( parse($.input), %!params );
    }

    sub parse( Str $in ) {
        # RAKUDO: when #58676 will be resolved use: 
        # $in ~~ HTML::Template::Grammar.new;
        $in ~~ HTML::Template::Grammar::TOP;
        die("No match") unless ~$/;
        return $/<contents>;
    }

    # We doing this using {*} in asterisk brunch.
    sub substitute( $contents, %params ) {
        my $output = ~$contents<plaintext>;

        for ($contents<chunk> // ()) -> $chunk {

            if $chunk<directive><insertion> -> $i {
                my $key = $i<attributes><name>;
                my $value = %params{$key};

                if $i<attributes><escape> {
                    my $et = ~$i<attributes><escape>[0];
                    # RAKUDO: Segaful here :(
                    #$value = escape($value, $et);
                    if $et eq 'HTML' {
                        $value = escape($value, 'HTML');
                    } 
                    elsif $et eq 'URL' | 'URI' {
                        $value = escape($value, 'URL');
                    }

                }
                $output ~= ~$value;
            }
            elsif $chunk<directive><if_statement> {
                my $key = ~$chunk<directive><if_statement><attributes><name>;
                my $condition = %params{$key};
                if $condition {
                    $output ~= substitute(
                                 $chunk<directive><if_statement><contents>,
                                 %params
                               );
                }
                elsif $chunk<directive><if_statement><else> {
                    $output ~= substitute(
                                 $chunk<directive><if_statement><else>[0],
                                 %params
                               );
                }
            }
            elsif $chunk<directive><for_statement> {
                my $key = ~$chunk<directive><for_statement><attributes><name><val>;
                my $iterations = %params{$key};
                # RAKUDO: This should exhibit the correct behaviour, but due
                # to a bug having to do with for loops and recursion, it
                # doesn't. [perl #58392]
                for $iterations.values -> $iteration {
                    $output ~= substitute(
                                 $chunk<directive><for_statement><contents>,
                                 $iteration
                               );
                }
            }
            elsif $chunk<directive><include> {
                my $file = ~$chunk<directive><include><attributes><name><val>;
                if $file ~~ :e  {
                    $output ~= substitute(
                                 parse( slurp($file) ),
                                 %params
                             );
                }
            }

            $output ~= ~$chunk<plaintext>;
        }
        return $output;
    }
}

# vim:ft=perl6
