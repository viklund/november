use v6;

use Text::Escape;
use HTML::Template::Grammar;

class HTML::Template;

has $!in;
has %!params;

method from_string( Str $in ) {
    return self.new(in => $in);
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
    return self.substitute( self.parse, %!params );
}

method parse( $in? ) {
    # RAKUDO: when #58676 will be resolved use: 
    # $in ~~ HTML::Template::Grammar.new;
    ($in || $!in) ~~ HTML::Template::Grammar::TOP;
    die("No match") unless $/;
    return $/<contents>;
}

method substitute( $contents, %params ) {
    my $output = ~$contents<plaintext>;

    for ($contents<chunk> // ()) -> $chunk {

        if $chunk<directive><insertion> -> $i {
            my $key = ~$i<attributes><name>;

            my $value; 
            if (defined %params{$key}) {
                $value = %params{$key}; 
            } else {
                $value = %!params{$key};
            }
            
            # RAKUDO: Scalar type not implemented yet
            warn "Param $key is a { $value.WHAT }" unless $value ~~ Str | Int;

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
                $output ~= self.substitute(
                                $chunk<directive><if_statement><contents>,
                                %params
                            );
            }
            elsif $chunk<directive><if_statement><else> {
                $output ~= self.substitute(
                                $chunk<directive><if_statement><else>[0],
                                %params
                            );
            }
        }
        elsif $chunk<directive><for_statement> -> $for {
            my $key = ~$for<attributes><name><val>;

            my $iterations = %params{$key};
            #say "iterations:" ~ $iterations.perl;

            for $iterations.values -> $iteration {
            #say "iteration:" ~ $iteration.perl;
                $output ~= self.substitute(
                                $for<contents>,
                                $iteration
                            );
            }
        }
        elsif $chunk<directive><include> {
            my $file = ~$chunk<directive><include><attributes><name><val>;
            if $file ~~ :e  {
                $output ~= self.substitute(
                                self.parse( slurp($file) ),
                                %params
                            );
            }
        }

        $output ~= ~$chunk<plaintext>;
    }
    return $output;
}

# vim:ft=perl6
