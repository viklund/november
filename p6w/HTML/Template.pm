use v6;

grammar HTML::Template::Substitution {
    regex TOP   { ^ <contents> $ };

    regex contents { <plain> <chunk>* };
    regex chunk { <directive> <plain> };
    regex plain { [ <!before '<TMPL_' >. ]* };

    token directive  {
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

    method with_param($parameter) {
        die "Need to test/implement with_param";
    }

    method with_params($parameters) {
        $.parameters = $parameters;
        return self;
    }

    # RAKUDO: We eventually want to do this using {*} ties.
    sub substitute( $contents, $parameters ) {
        my $output = $contents<plain>;

        for ($contents<chunk> // ()) -> $chunk {

            if $chunk<directive><insertion> {
                my $key = $chunk<directive><insertion><attributes><name>;
                my $value = $parameters{$key};
                $output ~= $value;
            }
            elsif $chunk<directive><if_statement> {
                my $key = $chunk<directive><if_statement><attributes><name>;
                my $condition = $parameters{$key};
                if $condition {
                    # TODO: Test that recursive if works
                    $output ~= substitute(
                                 $chunk<directive><if_statement><contents>,
                                 $parameters
                               );
                }
            }
            elsif $chunk<directive><for_statement> {
                my $key = $chunk<directive><for_statement><attributes><name>;
                my $iterations = $parameters{$key};
                for $iterations.values -> $iteration {
                    # TODO: Test that recursive for works
                    $output ~= substitute(
                                 $chunk<directive><for_statement><contents>,
                                 $iteration
                               );
                }
            }

            $output ~= $chunk<plain>;
        }
        return $output;
    }

    method output() {
        $.input ~~ HTML::Template::Substitution::TOP;

        die("No match") unless $/;

        return substitute( $/<contents>, $.parameters );
    }
}
