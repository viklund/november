use v6;

grammar Tokenizer {
    regex TOP { ^ <token>* $ }
    regex token { <bold_marker> | <italic_marker> | <wikilink> | <extlink> |
                  <entity> | <plain> | <malformed> }
    regex bold_marker { '&#039;&#039;&#039;' }
    regex italic_marker { '&#039;&#039;' }

    regex wikilink { '[[' \s*  <page> \s* ']]' }
    # RAKUDO <after> is not implemented
    #regex page { [<!before ']]'> \N]+<!after \s> }
    regex page { \N+? }

    regex extlink { '[' \s* <url> [\s+ <title>]? \s* ']' }
    regex url { [<!before ']'> \S]+ }
    regex title { [<!before ']'> .]+ }

    regex entity { '&amp;mdash;' }

    regex plain { [<!before '&#039;&#039;'> <!before '['>
                   <!before '&amp;mdash;'> .]+ }
    regex malformed { '[[' | '[' }
}

class Text::Markup::Wiki::MediaWiki {

    sub entities(*@words) {
        return map { "&$_;" }, @words.values;
    }

    sub merge_consecutive_paragraphs(*@parlist is copy) {
        for 0 ..^ @parlist.elems-1 -> $ix {
            if @parlist[$ix] ~~ /^'<p>'/ && @parlist[$ix+1] ~~ /^'<p>'/ {
                @parlist[$ix+1] = @parlist[$ix] ~ @parlist[$ix+1];
                @parlist[$ix+1] .= subst( '</p><p>', ' ' );
                @parlist[$ix] = Mu;
            }
            elsif @parlist[$ix] ~~ /^'<uli>'/ && @parlist[$ix+1] ~~ /^'<uli>'/
            || @parlist[$ix] ~~ /^'<oli>'/ && @parlist[$ix+1] ~~ /^'<oli>'/ {
                @parlist[$ix+1] = [~] @parlist[$ix], "\n", @parlist[$ix+1];
                @parlist[$ix] = Mu;
            }
        }

        my &strip_prefix = {
            # RAKUDO: -> $/ hack is nonportable; rakudo can't directly use match
            # vars in subst closures
            .subst(/'<' ('/'?) <[uo]> 'li>'/, -> $/ { '<' ~ $0 ~ 'li>' }, :g)
        };

        my &surround_with_list = {
            $^line ~~ /^'<uli>'/   ?? "<ul>\n{strip_prefix($line)}\n</ul>"
            !! $line ~~ /^'<oli>'/ ?? "<ol>\n{strip_prefix($line)}\n</ol>"
                                   !! $line;
        }

        return @parlist.grep( { $_ } ).map( { surround_with_list($_) } );
    }

    # Turns a style on of it was off, and vice versa. Outputs the result.
    # In case it was on, also turns off all styles pushed after that style.
    # In case it was off and the style was found in @promises, this token
    # cancels the one in @promises, and nothing is output.
    sub toggle(@style_stack is rw, @promises is rw, $marker) {
        if $marker ~~ any(@style_stack) {
            while @style_stack[@style_stack.end] ne $marker {
                my $t = @style_stack.pop();
                @promises.push($t);
                take "</$t>";
            }
            take '</' ~ @style_stack.pop() ~ '>';
        }
        else {
            if $marker ~~ any(@promises) {
                @promises = grep { $_ !=== $marker }, @promises;
            }
            else {
                @style_stack.push($marker);
                take "<$marker>";
            }
        }
    }

    sub format_line($line, :$link_maker, :$extlink_maker, :$author) {

        my $line_rw = $line;
        my $partype = 'p';
        if $line.substr(0, 1) eq '*' {
            $partype = 'uli';
            $line_rw = $line.substr(1);
        }
        elsif $line.substr(0, 1) eq '#' {
            $partype = 'oli';
            $line_rw = $line.substr(1);
        }
        elsif $line ~~ /^ '==' (.*) '==' $/ {
            $partype = 'h2';
            $line_rw = ~$/[0];
        }

        my $trimmed = $line_rw;
        $trimmed .= subst( / ^ \s+ /, '' );
        $trimmed .= subst( / \s+ $ /, '' );

        my $cleaned_of_whitespace = $trimmed.trans( / \s+ / => ' ' );

        my $xml_escaped = $cleaned_of_whitespace.trans(
            [           '<', '>', '&', '\''   ] =>
            [ entities < lt   gt  amp  #039 > ]
        );

        $xml_escaped .= subst( / '&amp;#' /, '&#', :g );

        # A stack of all the active styles, in order of activation
        my @style_stack;

        # The styles that were just closed because of mis-nesting, and which
        # might have to be opened again
        my @promises;

        my $result = join '', gather {
            Tokenizer.parse($xml_escaped) or return "Couldn't parse '$line'";

            for $/<token>.values // () -> $token {
                if $token<bold_marker> {
                    toggle(@style_stack, @promises, 'b');
                }
                elsif $token<italic_marker> {
                    toggle(@style_stack, @promises, 'i');
                }
                elsif $token<wikilink> {
                    take defined($link_maker)
                            ?? $link_maker(~$token<wikilink><page>, Any)
                            !! ~$token<wikilink>;
                }
                elsif $token<extlink> {
                    my $url = ~$token<extlink><url>;
                    my $title;

                    # RAKUDO: <foo>? should be Nil if no match, but is []
                    #if defined $token<extlink><title> {
                    if $token<extlink><title> {
                        # RAKUDO: return 1 from ~$token<extlink><title> if title defined,
                        # but thats works:
                        $title = ~$token<extlink><title>;
                    }
                    else { 
                        $title = $url;
                    }
                    
                    take defined($extlink_maker)
                            ?? $extlink_maker($url, $title)
                            !! ~$token<extlink>;
                }
                elsif $token<entity> {
                    # TODO: Generalize.
                    take '—';
                }
                else {
                    push @style_stack, @promises;
                    take join '', map { "<$_>" }, @promises;
                    @promises = ();
                    take ~$token;
                }
            }

            take join '', map { "</$_>" }, reverse @style_stack;
        }

        return sprintf '<%s>%s</%s>', $partype, $result, $partype;
    }

    sub format_paragraph($paragraph, :$link_maker, :$extlink_maker, :$author) {
        # RAKUDO: This could use some ==>

        return
          merge_consecutive_paragraphs
          map { format_line($^line, :link_maker($link_maker),
                                    :extlink_maker($extlink_maker),
                                    :author($author)) },
          $paragraph.split("\n");
    }

    method format($text, :$link_maker, :$extlink_maker, :$author) {
        # RAKUDO: This could use some ==>
        return
          join "\n\n",
          map { format_paragraph($_, :link_maker($link_maker),
                                     :extlink_maker($extlink_maker),
                                     :author($author)) },
          $text.split(/\n ** 2..*/);
    }
}

# vim:ft=perl6
