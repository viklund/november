use v6;

grammar Wiki::Markup::Minimal::Syntax {

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
