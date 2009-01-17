grammar Text::Markup::Wiki::Minimal::Grammar {

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
