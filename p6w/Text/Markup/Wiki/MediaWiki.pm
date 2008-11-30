use v6;

grammar Tokenizer {
    regex TOP { ^ <token>* $ }
    regex token { <bold_marker> | <italic_marker> | <plain> }
    regex bold_marker { '&#039;&#039;&#039;' }
    regex italic_marker { '&#039;&#039;' }
    regex plain { [<!before '&#039;&#039;'> .]+ }
}

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

        my $result;
        my $italic_flag = False;
        my $bold_flag   = False;

        $xml_escaped ~~ Tokenizer;
        for $/<token>.values -> $token {
            if $token<bold_marker> {
                $result ~= ($bold_flag = !$bold_flag) ??  '<b>' !! '</b>';
            }
            elsif $token<italic_marker> {
                $result ~= ($italic_flag = !$italic_flag) ?? '<i>' !! '</i>';
            }
            else {
                $result ~= ~$token;
            }
        }

        if $italic_flag {
            $result ~= '</i>';
        }
        if $bold_flag {
            $result ~= '</b>';
        }

        return sprintf '<%s>%s</%s>', $partype, $result, $partype;
    }

    sub format_paragraph($paragraph, :$link_maker, :$author) {
        # RAKUDO: This could use some ==>
        return
          merge_consecutive_paragraphs
          map { format_line($^line, :$link_maker, :$author) },
          $paragraph.split("\n");
    }

    method format($text, :$link_maker, :$author) {
        # RAKUDO: This could use some ==>
        return
          join "\n\n",
          map { format_paragraph($_, :$link_maker, :$author) },
          $text.split(/\n ** 2..*/);
    }
}

# vim:ft=perl6
