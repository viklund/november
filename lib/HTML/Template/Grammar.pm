use v6;
# RAKUDO: It is uncertain whether a 'grammar' keyword can start a file, just
#         like 'class' can.

grammar HTML::Template::Grammar {
    regex TOP { ^ <contents> $ };

    regex contents  { <plaintext> <chunk>* };
    regex chunk     { <directive> <plaintext> };
    regex plaintext { [ <!before '<TMPL_' ><!before '</TMPL_' >. ]* };

    token directive {
                    | <insertion>
                    | <if_statement>
                    | <for_statement>
                    | <include>
                    };

    regex insertion {
        <.tag_start> 'VAR' <attributes> '>'
    };

    regex if_statement { 
        <.tag_start> 'IF' <attributes> '>' 
        <contents>
        [ '<TMPL_ELSE>' <else=contents> ]?
        '</TMPL_IF>' 
    };

    regex for_statement {
        <.tag_start> [ 'FOR' | 'LOOP' ] <attributes> '>'
        <contents>
        '</TMPL_' [ 'FOR' | 'LOOP' ] '>'
    };

    regex include {
        <.tag_start> 'INCLUDE' <attributes> '>'
    };

    token tag_start  { '<TMPL_' };
    token attributes { \s+ 'NAME='? <name> [\s+ 'ESCAPE=' <escape> ]? };
    token name       { $<val>=\w+ | <lctrls> | [<.qq> $<val>=[ <[ 0..9 '/._' \- \\ ] +alpha>* ] <.qq>] };
    regex qq         { '"' };
    token lctrls     { <lc_last> | <lc_first> };
    regex lc_last    { '!LAST' };
    regex lc_first   { '!FIRST' };
    token escape     { 'NONE' | 'HTML' | 'URL' | 'URI' | 'JS' | 'JAVASCRIPT' };
};
