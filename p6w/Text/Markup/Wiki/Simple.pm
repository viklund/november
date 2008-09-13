grammar Text::Markup::Wiki::Simple {

    token TOP { ^ <parchunk>+ $ };

    token parchunk { <twext> || <wikimark> || <metachar> || <malformed> };

    # RAKUDO: a token may not be called 'text' [perl #57864]
    token twext { [ <alnum> || <otherchar> || <sp> ]+ };

    token otherchar { <[ !..% (../ : ; ? @ \\ ^..` {..~ ]> };

    token sp { ' ' | \n };

    token wikimark { '[[' <twext> ']]' };

    token metachar { '<' || '>' || '&' || \' };

    token malformed { '[' || ']' }
}
