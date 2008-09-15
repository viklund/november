use v6;

use Text::Escape;

grammar HTML::Template::Substitution {
    regex TOP { ^ <contents> $ };

    regex contents  { <plaintext> <chunk>* };
    regex chunk     { <directive> <plaintext> };
    regex plaintext { [ <!before '<TMPL_' ><!before '</TMPL_' >. ]* };

    token directive {
                    | <insertion>
                    | <if_statement>
                    | <for_statement>
                    | <include>
                    };

    regex insertion {
        <.tag_start> 'VAR' <attributes> '>'
    };

    regex if_statement { 
        <.tag_start> 'IF' <attributes> '>' 
        <contents>
        [ '<TMPL_ELSE>' <else=contents> ]?
        '</TMPL_IF>' 
    };

    regex for_statement {
        <.tag_start> 'FOR' <attributes> '>'
        <contents>
        '</TMPL_FOR>'
    };

    regex include {
        <.tag_start> 'INCLUDE' <attributes> '>'
    };

    token tag_start  { '<TMPL_' };
    token name       { $<val>=\w+ | <.qq> $<val>=[ <[ 0..9 '/._' \- // ] +alpha>* ] <.qq> };
    regex qq         { '"' };
    token escape     { 'NONE' | 'HTML' | 'URL' | 'JS' | 'JAVASCRIPT' };
    token attributes { \s+ 'NAME='? <name> [\s+ 'ESCAPE=' <escape> ]? };
};

class HTML::Template {
    has $.input;
    has %!params;

    method param( Pair $param ) {
        %!params{$param.key} = $param.value;
    }

    method from_string( Str $input) {
        return self.new(input => $input);
    }

    method from_file($file_path) {
        return self.from_string( slurp($file_path) );
    }

    method with_params( Hash %params) {
        %!params = %params;
        return self;
    }

    # RAKUDO: We eventually want to do this using {*} ties.
    sub substitute( $contents, %params ) {
        my $output = $contents<plaintext>;

        for ($contents<chunk> // ()) -> $chunk {

            # RAKUDO: The following blocks will be greatly de-cluttered by
            # making use of the future ability in Rakudo to specify closure
            # parameters in if statements. [perl #58396]
            #if $chunk<directive><insertion> -> $_ { # and so on for the others
            if $chunk<directive><insertion> {
                my $key = $chunk<directive><insertion><attributes><name>;
                my $value = %params{$key};

                if $chunk<directive><insertion><attributes><escape> {
                    $value = escape( $value, $chunk<directive><insertion><attributes><escape> );
                }
 
                $output ~= $value;
            }
            elsif $chunk<directive><if_statement> {
                my $key = $chunk<directive><if_statement><attributes><name>;
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
                my $key = $chunk<directive><for_statement><attributes><name><val>;
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
                my $file = $chunk<directive><include><attributes><name><val>;
                if file_exists( $file ) {
                    $output ~= substitute(
                                 parse( slurp($file) ),
                                 %params
                             );
                }
            }

            $output ~= $chunk<plaintext>;
        }
        return $output;
    }

    method output() {
        return substitute( parse($.input), %!params );
    }

}

sub parse( Str $in ) {
    # RAKUDO: when #58676 will be resolved use: 
    # $in ~~ HTML::Template::Substitution::TOP.new;
    $in ~~ HTML::Template::Substitution::TOP;
    die("No match") unless $/;
    return $/<contents>;
}

sub file_exists( $file ) {
    # RAKUDO: use ~~ :e
    my $exists = False;
    try {
        my $fh = open( $file );
        $exists = True;
    }
    return $exists;
}
