use v6;

grammar Text__Markup__Wiki__Minimal__Syntax {

    token TOP { ^ [<heading> || <parchunk>+] $ };

    token heading { '==' <parchunk>+ '==' };

    token parchunk { <twext> || <wikimark> || <metachar> || <malformed> };

    # RAKUDO: a token may not be called 'text' [perl #57864]
    token twext { [ <.alnum> || <.otherchar> || <.whitespace> ]+ };

    token otherchar { <[ !..% (../ : ; ? @ \\ ^..` {..~ ]> };

    token whitespace { ' ' | \n };

    token wikimark { '[[' \s?  <link> [\s+ <link_title>]? \s? ']]' };
    
    regex link { <[:/._@\-0..9]+alpha>+ };
    regex link_title { <-[\]]>+ };

    token metachar { '<' || '>' || '&' || \' };

    token malformed { '[' || ']' }
}

class Text::Markup::Wiki::Minimal {
    has $.link_maker is rw;

    method format($text ) {
        my @pars = grep { $_ ne "" },
                   map { $_.subst( / ^ \n /, '' ) },
                   $text.split( /\n\n/ );

        my @formatted;
        for @pars -> $par {

            my $result;

            # RAKUDO: when #58676 and #59928 will be resolved use: 
            # $par ~~ Text::Markup::Wiki::Minimal::Syntax.new;
            if $par ~~ Text__Markup__Wiki__Minimal__Syntax::TOP {

                if $/<heading> {
                    my $heading = ~$/<heading><parchunk>[0];
                    $heading .= subst( / ^ \s+ /, '' );
                    $heading .= subst( / \s+ $ /, '' );
                    $result = "<h1>$heading</h1>";
                }
                else {
                    $result = '<p>';

                    for $/<parchunk> {
                        if $_<twext> { 
                            $result ~= $_<twext>;
                        }
                        elsif $_<wikimark> {
                            if $.link_maker {
                                # RAKUDO: second arg transform to '1' by some dark magic 
                                # $result ~= $.link_maker( ~$_<wikimark><link>, ~$_<wikimark><link_title> );
                                # workaround:
                                my $title = $_<wikimark><link_title>;
  
                                $result ~= $.link_maker( ~$_<wikimark><link>, $title );
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

}

# vim:ft=perl6
