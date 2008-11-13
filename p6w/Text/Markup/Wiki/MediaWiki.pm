use v6;

class Text::Markup::Wiki::MediaWiki {

    method format($text, :$link_maker) {
        my @result_pars;

        my @split = gather {
            my $text_copy = $text;
            while $text_copy.index("\n\n") -> $ix {
                take $text_copy.substr(0, $ix);
                $text_copy .= substr($ix);
                while $text_copy.substr(0,1) eq "\n" {
                    $text_copy .= substr(1);
                }
            }
            if $text_copy {
                take $text_copy;
            }
        };

        # RAKUDO: Awaiting HLL type conversion
        #for split(/\n ** 2..*/, $text) -> $paragraph {
        for @split -> $paragraph {
            #my $cleaned_of_whitespace = $paragraph.trans(
            #    [ /\s+/ => ' ' ]
            #);
            my @cleaned_pars;

            my $paragraph_copy = $paragraph;
            while $paragraph_copy ~~ /\s/ {
                push @cleaned_pars, $paragraph_copy.substr(0, $/.from);
                $paragraph_copy .= substr($/.from);
                while $paragraph_copy ~~ /^\s/ {
                    $paragraph_copy .= substr(1);
                }
            }
            if $paragraph_copy {
                push @cleaned_pars, $paragraph_copy;
            }

            my $cleaned_of_whitespace = join ' ', @cleaned_pars;

            push @result_pars, "<p>$cleaned_of_whitespace</p>";
        }

        return join "\n\n", @result_pars;
    }
}

# vim:ft=perl6
