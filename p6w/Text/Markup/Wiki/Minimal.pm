use v6;

# RAKUDO: Inheriting from classes in other modules does not quite work yet
#use Text::Markup::Wiki;

# ...so instead we inline the method inside the class for now.

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

class Text::Markup::Wiki::Minimal { # is Text::Markup::Wiki {

    has $.wiki is rw;

    method format($text is rw) {
        # RAKUDO: $text.split( /\n\n/ )
        my @pars = grep { $_ ne "" },
                   map { $_.subst( / ^ \n /, '' ) },
                   $text.split("\r\n\r\n");

        my @formatted;
        for @pars -> $par {
            if $par ~~ Text::Markup::Wiki::Minimal::Syntax::paragraph {

                my $result;

                if $/<heading> {
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
                            when 'metachar'  { $result ~= self.quote($text) }
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
}
