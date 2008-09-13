use v6;

grammar Text::Markup::Wiki::Minimal::Syntax {

    token paragraph { ^ <parchunk>+ $ };

    token parchunk { <twext> || <wikimark> || <metachar> || <malformed> };

    # RAKUDO: a token may not be called 'text' [perl #57864]
    token twext { [ <alnum> || <otherchar> || <sp> ]+ };

    token otherchar { <[ !..% (../ : ; ? @ \\ ^..` {..~ ]> };

    token sp { ' ' | \n };

    token wikimark { '[[' <twext> ']]' };

    token metachar { '<' || '>' || '&' || \' };

    token malformed { '[' || ']' }
}

class Text::Markup::Wiki::Minimal {

    has $.wiki is rw;

    method format($text is rw) {
        # RAKUDO: $text.split( /\n\n/ )
        my @pars = grep { $_ ne "" },
                   map { $_.subst( / ^ \n /, '' ) },
                   $text.split("\r\n\r\n");

        my @formatted;
        for @pars -> $par {
            if $par ~~ Text::Markup::Wiki::Minimal::Syntax::paragraph {
                # RAKDUO: Must match again. [perl #57858]
                $par ~~ Text::Markup::Wiki::Minimal::Syntax::paragraph;

                my $result;

                if $/<heading> {
                    # RAKDUO: Must match again. [perl #57858]
                    $par ~~ Text::Markup::Wiki::Minimal::Syntax::paragraph;

                    $result = '<h1>'
                        ~ $/<heading>.values[0].subst( / ^ \s+ /, '' ).subst(
                          / \s+ $ /, '')
                        ~ '</h1>';
                }
                else {
                    # RAKDUO: Must match again. [perl #57858]
                    $par ~~ Text::Markup::Wiki::Minimal::Syntax::paragraph;
                    $result = '<p>';

                    for $/<parchunk> -> $chunk {
                        my $text = $chunk.values[0];
                        given $chunk.keys[0] {
                            when 'twext'     { $result ~= $text }
                            when 'wikimark' {
                                my $page = substr($text, 2, -2);
                                $result ~= $.wiki.make_link($page)
                            }
                            when 'metachar'  { $result ~= quote($text) }
                            when 'malformed' { $result ~= $text }
                        }
                    }
                    $result ~= "</p>";

                    push @formatted, $result;
                }
            }
            else {
                push @formatted, '<p>Could not parse paragraph.</p>';
            }
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
