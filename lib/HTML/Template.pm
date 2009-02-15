class HTML::Template;

use Text::Escape;
use HTML::Template::Grammar;

has $!in;
has %!params;
has %!meta;

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
    # TODO: If used .parse fall tests, fix it! 
    ($in || $!in) ~~ /<HTML::Template::Grammar::TOP>/;
    die("No match") unless $/;
    return $/<HTML::Template::Grammar::TOP><contents>;
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
                # RAKUDO: Segfault here :(
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
        elsif $chunk<directive><if_statement> -> $if {
            my $cond;
            if $if<attributes><name><lctrls> -> $lc {
                if %!meta<loops><current> -> $c {
                    if $lc<lc_last> {
                        $cond = ?($c<elems> == $c<iteration>);
                    } 
                    elsif $lc<lc_first> {
                        $cond = ?($c<iteration> == 1);
                    }
                }
            }
            else {
                $cond = %params{~$if<attributes><name>};
            }

            if $cond {
                $output ~= self.substitute(
                                $if<contents>,
                                %params
                            );
            }
            elsif $if<else> {
                $output ~= self.substitute(
                                $if<else>[0],
                                %params
                            );
            }
        }
        elsif $chunk<directive><for_statement> -> $for {
            my $key = ~$for<attributes><name><val>;

            my $iterations = %params{$key};
            
            # RAKUDO: Rakudo doesn't understand autovivification of multiple
            # hash indices %!meta<loops><current> = $key; [perl #61740]
            %!meta<loops> = {} unless defined %!meta<loops>;

            # that will fail on nested same-named loops... hm
            %!meta<loops>{$key} = {elems => $iterations.elems, iteration => 0};
            %!meta<loops><current> = %!meta<loops>{$key};
            
            for $iterations.values -> $iteration {
                %!meta<loops>{$key}<iteration>++;
                $output ~= self.substitute(
                                $for<contents>,
                                $iteration
                            );
            }
        }
        elsif $chunk<directive><include> {
            my $file = ~$chunk<directive><include><attributes><name><val>;
            %params<TMPL_PATH> = '' if not defined %params<TMPL_PATH>;
            $file = %params<TMPL_PATH> ~ $file;
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
