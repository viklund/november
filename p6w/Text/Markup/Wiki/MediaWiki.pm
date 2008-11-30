use v6;

class Text::Markup::Wiki::MediaWiki {

    sub entities(*@words) {
        return map { "&$_;" }, @words.values;
    }

    sub merge_consecutive_paragraphs(*@parlist) {
        for 0 ..^ @parlist.elems-1 -> $ix {
            if @parlist[$ix] ~~ /^'<p>'/ && @parlist[$ix+1] ~~ /^'<p>'/ {
                @parlist[$ix+1] = @parlist[$ix] ~ @parlist[$ix+1];
                @parlist[$ix+1] .= subst( '</p><p>', ' ' );

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

        # This method is far to simplistic, but will get us a few passing
        # tests along the way.
        my $italic_regex
            = / <!after '&#039;'> '&#039;&#039;' <!before '&#039;'> (.*?)
                <!after '&#039;'> '&#039;&#039;' <!before '&#039;'> /;
        while $result ~~ $italic_regex {
            $result .= subst( $italic_regex, { "<i>$0</i>" } );
        }

        my $bold_regex
            = / '&#039;&#039;&#039;' (.*?) '&#039;&#039;&#039;' /;
        while $result ~~ $bold_regex {
            $result .= subst( $bold_regex, { "<b>$0</b>" } );
        }

        if defined $link_maker {
            my $link_regex = / '[[' (<-[\]]>+) ']]' /; # /
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
