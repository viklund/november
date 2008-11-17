use v6;

class Text::Markup::Wiki::MediaWiki {

    # RAKUDO: real slices don't work yet
    sub slice(@a, @i) {
        my @res;
        for @i.values -> $ix {
            @res.push(@a[$ix])
        }
        return @res
    }

    sub entities(*@words) {
        return map { "&$_;" }, @words.values;
    }

    sub merge_consecutive_paragraphs(*@parlist) {
        for 0 ..^ @parlist.elems-1 -> $ix {
            if @parlist[$ix] ~~ /^'<p>'/ && @parlist[$ix+1] ~~ /^'<p>'/ {
                @parlist[$ix+1] = @parlist[$ix] ~ @parlist[$ix+1];
                # RAKUDO: .= is broken here, for some reason [perl #60620]
                @parlist[$ix+1] = @parlist[$ix+1].subst( '</p><p>', ' ' );

                @parlist[$ix] = '<';
            }
        }

        return @parlist.grep( { $_ ne '<' } );
    }


    sub format_line($line is rw) {
        my $partype = 'p';
        if $line ~~ /^ '==' (.*) '==' $/ {
            $partype = 'h2';
            $line = ~$/[0];
        }

        my $trimmed = $line;
        $trimmed .= subst( / ^ \s+ /, '' );
        $trimmed .= subst( / \s+ $ /, '' );

        my $cleaned_of_whitespace = $trimmed.trans(
            [ /\s+/ => ' ' ]
        );

        my $xml_escaped = $cleaned_of_whitespace.trans(
            [           '<', '>', '&', '\''   ] =>
            [ entities < lt   gt  amp  #039 > ]
        );

        return sprintf '<%s>%s</%s>', $partype, $xml_escaped, $partype;
    }

    sub format_paragraph($paragraph) {
        # RAKUDO: This could use some ==>
        return merge_consecutive_paragraphs
               map { format_line($^line) },
               $paragraph.split("\n");
    }

    method format($text, :$link_maker) {
        my @result_pars;

        my @paragraphs = $text.split(/\n ** 2..*/);
        while @paragraphs.shift -> $paragraph {
            # RAKUDO: Needed right now due to HLL non-mapping.
            my $paragraph_copy = $paragraph;

            push @result_pars, format_paragraph($paragraph_copy);
        }

        return join "\n\n", @result_pars;
    }
}

# vim:ft=perl6
