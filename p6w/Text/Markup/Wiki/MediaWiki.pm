use v6;

class Text::Markup::Wiki::MediaWiki {

    sub entities(*@words) {
        return map { "&$_;" }, @words.values;
    }

    sub merge_consecutive_paragraphs(*@parlist) {
        for 0 ..^ @parlist.elems-1 -> $ix {
            if @parlist[$ix] ~~ /^'<p>'/ && @parlist[$ix+1] ~~ /^'<p>'/ {
                @parlist[$ix+1] = @parlist[$ix] ~ @parlist[$ix+1];
                # RAKUDO: `@a[$i] .=` is broken [perl #60620]
                @parlist[$ix+1] = @parlist[$ix+1].subst( '</p><p>', ' ' );

                @parlist[$ix] = undef;
            }
        }

        return @parlist.grep( { $_ } );
    }

    sub format_line($line is rw, :$link_maker, :$author) {
        my $partype = 'p';
        if $line ~~ /^ '==' (.*) '==' $/ {
            $partype = 'h2';
            $line = ~$/[0];
        }

        my $trimmed = $line;
        $trimmed .= subst( / ^ \s+ /, '' );
        $trimmed .= subst( / \s+ $ /, '' );

        my $cleaned_of_whitespace = $trimmed.trans( [ /\s+/ => ' ' ] );

        my $xml_escaped = $cleaned_of_whitespace.trans(
            [           '<', '>', '&', '\''   ] =>
            [ entities < lt   gt  amp  #039 > ]
        );

        my $result = $xml_escaped;

        if defined $link_maker {
            my $link_regex = / \[\[ (<-[\]]>+) \]\] /; # /
            while $result ~~ $link_regex {
                $result .= subst( $link_regex, { $link_maker($0) } );
            }
        }

        return sprintf '<%s>%s</%s>', $partype, $result, $partype;
    }

    sub format_paragraph($paragraph, :$link_maker, :$author) {
        # RAKUDO: This could use some ==>
        return merge_consecutive_paragraphs
               map { format_line($^line, :$link_maker, :$author) },
               $paragraph.split("\n");
    }

    method format($text, :$link_maker, :$author) {
        my @result_pars
            = join "\n\n",
              map { format_paragraph($_, :$link_maker, :$author) },
              $text.split(/\n ** 2..*/);
    }
}

# vim:ft=perl6
