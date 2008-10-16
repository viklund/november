use v6;

grammar Text__Markup__Wiki__Minimal__Syntax {

    token paragraph { ^ [<heading> || <parchunk>+] $ };

    token heading { '==' <parchunk>+ '==' };

    token parchunk { <twext> || <wikimark> || <metachar> || <malformed> };

    # RAKUDO: a token may not be called 'text' [perl #57864]
    token twext { [ <.alnum> || <.otherchar> || <.whitespace> ]+ };

    token otherchar { <[ !..% (../ : ; ? @ \\ ^..` {..~ ]> };

    token whitespace { ' ' | \n };

    token wikimark { '[[' <twext> ']]' };

    token metachar { '<' || '>' || '&' || \' };

    token malformed { '[' || ']' }
}

class Text__Markup__Wiki__Minimal {

    method format($text, :$link_maker) {
        # RAKUDO: $text.split( /\n\n/ )
        my @pars = grep { $_ ne "" },
                   map { $_.subst( / ^ \n /, '' ) },
                   $text.split("\n\n");

        my @formatted;
        for @pars -> $par {

            my $result;

            # RAKUDO: when #58676 will be resolved use: 
            # $par ~~ Text__Markup__Wiki__Minimal__Syntax.new;
            if $par ~~ Text__Markup__Wiki__Minimal__Syntax::paragraph {

                if $/<heading> {
                    my $heading = $/<heading><parchunk>[0];
                    $heading .= subst( / ^ \s+ /, '' );
                    $heading .= subst( / \s+ $ /, '' );
                    $result = "<h1>$heading</h1>";
                }
                else {
                    $result = '<p>';

                    for $/<parchunk> -> $chunk {
                        my $text = $chunk.values[0];
                        given $chunk.keys[0] {
                            when 'twext'     { $result ~= $text }
                            when 'wikimark' {
                                if $link_maker.defined {
                                    my $page = substr($text, 2, -2);
                                    $result ~= $link_maker($page);
                                }
                                else {
                                    $result ~= $text;
                                }
                            }
                            when 'metachar'  { $result ~= quote($text) }
                            when 'malformed' { $result ~= $text }
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
}

# vim:ft=perl6
