use v6;

grammar HTML::Template::Substitution {
    regex TOP { ^ <contents> $ };

    regex contents  { <plaintext> <chunk>* };
    regex chunk     { <directive> <plaintext> };
    regex plaintext { [ <!before '<TMPL_' ><!before '</TMPL_' >. ]* };

    token directive {
                    | <insertion>
                    | <if_statement>
                    | <for_statement>
                    };

    regex insertion {
        <.tag_start> 'VAR' <attributes> '>'
    };

    regex if_statement { 
        <.tag_start> 'IF' <attributes> '>' 
        <contents>
        '</TMPL_IF>' 
    };

    regex for_statement {
        <.tag_start> 'FOR' <attributes> '>'
        <contents>
        '</TMPL_FOR>'
    };

    token tag_start  { '<TMPL_' };
    token name       { \w+ };
    token escape     { 'NONE' | 'HTML' | 'URL' | 'JS' | 'JAVASCRIPT' };
    token attributes { \s+ 'NAME='? <name> [\s+ 'ESCAPE=' <escape> ]? };
};

class HTML::Template {
    has $.input;
    has $.parameters is rw;

    method from_string($input) {
        return self.new(input => $input);
    }

    method from_file($file_path) {
        return self.from_string( slurp($file_path) );
    }

    method with_param($parameter) {
        die "Need to test/implement with_param";
    }

    method with_params($parameters) {
        $.parameters = $parameters;
        return self;
    }

    # RAKUDO: We eventually want to do this using {*} ties.
    sub substitute( $contents, $parameters ) {
        my $output = $contents<plaintext>;

        for ($contents<chunk> // ()) -> $chunk {

            # RAKUDO: The following blocks will be greatly de-cluttered by
            # making use of the future ability in Rakudo to specify closure
            # parameters in if statements. [perl #58396]
            #if $chunk<directive><insertion> -> $_ { # and so on for the others
            if $chunk<directive><insertion> {
                my $key = $chunk<directive><insertion><attributes><name>;
                my $value = $parameters{$key};
                $output ~= $value;
            }
            elsif $chunk<directive><if_statement> {
                my $key = $chunk<directive><if_statement><attributes><name>;
                my $condition = $parameters{$key};
                if $condition {
                    $output ~= substitute(
                                 $chunk<directive><if_statement><contents>,
                                 $parameters
                               );
                }
            }
            elsif $chunk<directive><for_statement> {
                my $key = $chunk<directive><for_statement><attributes><name>;
                my $iterations = $parameters{$key};
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

            $output ~= $chunk<plaintext>;
        }
        return $output;
    }

    method output() {
        $.input ~~ HTML::Template::Substitution::TOP;

        die("No match") unless $/;

        return substitute( $/<contents>, $.parameters );
    }
}
