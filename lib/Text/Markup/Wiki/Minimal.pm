unit class Text::Markup::Wiki::Minimal;

method format($text, :$link_maker, :$extlink_maker) {
    my @pars = grep { $_ ne "" },
                map { $_.subst( / ^ \n /, '' ) },
                $text.split( /\n\n/ );

    my @formatted;
    for @pars -> $par {

        my $result;
        use Text::Markup::Wiki::Minimal::Grammar;
        Text::Markup::Wiki::Minimal::Grammar.parse($par);

        if $/ {

            if $/<heading> {
                my $heading = ~$/<heading><parchunk>[0];
                $heading .= subst( / ^ \s+ /, '' );
                $heading .= subst( / \s+ $ /, '' );
                $result = "<h1>{$heading}</h1>";
            }
            else {
                $result = '<p>';

                for $/<parchunk>.list {
                    if $_<twext> { 
                        $result ~= $_<twext>;
                    }
                    elsif $_<wikimark> {
                        if defined $link_maker {
                            # RAKUDO: second arg transform to '1' by some dark magic 
                            # $result ~= $link_maker( ~$_<wikimark><link>, ~$_<wikimark><link_title> );
                            # workaround:
                            my $title = $_<wikimark><link_title>;

                            $result ~= $link_maker( ~$_<wikimark><link>, $title );
                        }
                        else {
                            $result ~= $_<wikimark>;
                        }
                    }
                    elsif $_<metachar>  { 
                        $result ~= quote($_<metachar>) 
                    }
                    elsif $_<malformed> { 
                        $result ~= $_<malformed> 
                    }
                }
                $result ~= "</p>";
            }
        }
        else {
            $result = '<p>Could not parse paragraph.</p>';
        }

        push @formatted, $result;
    }

    return join "\n\n", @formatted;
}

sub quote($metachar) {
    # RAKUDO: Chained trinary operators do not do what we mean yet.
    return '&#039;' if $metachar eq '\'';
    return '&lt;'   if $metachar eq '<';
    return '&gt;'   if $metachar eq '>';
    return '&amp;'  if $metachar eq '&';
    return $metachar;
}


# vim:ft=perl6
