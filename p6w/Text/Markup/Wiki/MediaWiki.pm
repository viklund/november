use v6;

class Text::Markup::Wiki::MediaWiki {

    sub entities(*@words) {
        return map { "&$_;" }, @words.values;
    }

    method format($text, :$link_maker) {
        my @result_pars;

        for split(/\n ** 2..*/, $text) -> $paragraph {
            # RAKUDO: Needed right now due to HLL non-mapping.
            my $paragraph_copy = $paragraph;

            my $partype = 'p';
            if $paragraph ~~ /^ '==' (.*) '==' $/ {
                $partype = 'h2';
                $paragraph_copy = ~$/[0];
            }

            my $trimmed = $paragraph_copy;
            $trimmed .= subst( / ^ \s+ /, '' );
            $trimmed .= subst( / \s+ $ /, '' );

            my $cleaned_of_whitespace = $trimmed.trans(
                [ /\s+/ => ' ' ]
            );

            my $xml_escaped = $cleaned_of_whitespace.trans(
                [           '<', '>', '&', '\''   ] =>
                [ entities < lt   gt  amp  #039 > ]
            );

            push @result_pars,
                 sprintf '<%s>%s</%s>', $partype, $xml_escaped, $partype;
        }

        return join "\n\n", @result_pars;
    }
}

# vim:ft=perl6
