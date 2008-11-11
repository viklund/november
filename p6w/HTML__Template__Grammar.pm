grammar HTML__Template__Grammar {
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
        <.tag_start> 'FOR' <attributes> '>'
        <contents>
        '</TMPL_FOR>'
    };

    regex include {
        <.tag_start> 'INCLUDE' <attributes> '>'
    };

    token tag_start  { '<TMPL_' };
    token name       { $<val>=\w+ | <.qq> $<val>=[ <[ 0..9 '/._' \- // ] +alpha>* ] <.qq> };
    regex qq         { '"' };
    token escape     { 'NONE' | 'HTML' | 'URL' | 'JS' | 'JAVASCRIPT' };
    token attributes { \s+ 'NAME='? <name> [\s+ 'ESCAPE=' <escape> ]? };
};
