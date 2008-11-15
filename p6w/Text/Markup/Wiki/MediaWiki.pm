use v6;

class Text::Markup::Wiki::MediaWiki {

    sub entities(*@words) {
        return map { "&$_;" }, @words.values;
    }

    method format($text, :$link_maker) {
        my @result_pars;

        for split(/\n ** 2..*/, $text) -> $paragraph {
            # RAKUDO: Needed right now due to HLL non-mapping.
            $paragraph = $paragraph;
            my $cleaned_of_whitespace = $paragraph.trans(
                [ /\s+/ => ' ' ]
            );

            my $xml_escaped = $cleaned_of_whitespace.trans(
                [           '<', '>', '&', '\''  ] =>
                [ entities < lt   gt  amp  #039> ]
            );
            #my $xml_escaped = $cleaned_of_whitespace;

            push @result_pars, "<p>$xml_escaped</p>";
        }

        return join "\n\n", @result_pars;
    }
}

# vim:ft=perl6
