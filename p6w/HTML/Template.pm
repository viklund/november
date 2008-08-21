use v6;

class HTML::Template {

    has $.filename;
    has %!params;

    method param( Pair $param ) {
        %!params{$param.key} = $param.value;
    }

    method output() {
        # RAKUDO: Poor man's CATCH.
        my $worked = False;
        my $template;
        try {
            $template = slurp( $.filename );
            $worked = True;
        }
        die "Could not open $.filename" if !$worked;
        return self.serialize($template);
    }

    method serialize($text is rw) {
        my @loops;

        while ( $text ~~ / '<TMPL_' (<alnum>+) ' NAME=' (\w+) '>' / ) {
            my $directive = $0;
            my $name = $1;

            # `$s ne $a & $b` means `$s ne $a || $s ne $b`,
            # which is confusing, so we'll write it like this instead:
            die "Unrecognized directive" if !($directive eq 'VAR' | 'LOOP');

            my $value = %!params{$name}
              // die "$name is defined in the template but undefined in source";

            if $directive eq 'LOOP' {

                # TODO: In the presence of nested loops: this is wrong.
                unless $text ~~ / '<TMPL_LOOP NAME=' \w+ '>' (.*?)
                                  '</TMPL_LOOP>' / {
                    die "No closing </TMPL_LOOP>"
                }
                my $loop_inside = $0;

                # RAKUDO: Dotty methods don't work.
                $text = $text.subst( / '<TMPL_LOOP NAME=' \w+ '>' .*?
                                       '</TMPL_LOOP>' /,
                                     self.serialize_loop(
                                         $loop_inside,
                                         $value ));
            }
            else { # it's TMPL_VAR
                # RAKUDO: Dotty methods don't work.
                $text = $text.subst( / '<TMPL_VAR NAME=' \w+ '>' /,
                                     $value );
            }
        }

        # Also need to check whether some parameters went unused during the
        # substitution. This might be best to do here, or in param(), I don't
        # know. Probably in param, with the allowed parameters pre-cached.
        # It's a little bit tricky, though, once you take <TEMPL_LOOP> into
        # account. Need to think about that.
        return $text;
    }

    method serialize_loop($text is rw, @hashes) {
        my $result = "";

        for @hashes.values -> $hash {
            $result ~= self.serialize_iteration($text, $hash);
        }
        return $result;
    }

    method serialize_iteration($text, %hash) {
        my $result = $text;
        while ( $result ~~ / '<TMPL_' (<alnum>+) ' NAME=' (\w+) '>' / ) {
            my $directive = $0;
            my $name = $1;

            die "Nested TMPL_LOOPs not supported" if $directive eq 'LOOP';

            # `$s ne $a & $b` means `$s ne $a || $s ne $b`,
            # which is confusing, so we'll write it like this instead:
            die "Unrecognized directive" if !($directive eq 'VAR' | 'LOOP');

            # TODO: Converting it to lowercase here is definitely wrong.
            # But it works for now.
            my $value = %hash{$name.lc}
              // die "$name is defined in the template but undefined in source";

            if $directive eq 'LOOP' {

                # TODO: In the presence of nested loops: this is wrong.
                unless $result ~~ / '<TMPL_LOOP NAME=' \w+ '>' (.*?)
                                  '</TMPL_LOOP>' / {
                    die "No closing </TMPL_LOOP>"
                }
                my $loop_inside = $0;

                # RAKUDO: Dotty methods don't work.
                $result = $result.subst( / '<TMPL_LOOP NAME=' \w+ '>' .*?
                                       '</TMPL_LOOP>' /,
                                     self.serialize_loop(
                                         $loop_inside,
                                         $value ));
            }
            else { # it's TMPL_VAR
                # RAKUDO: Dotty methods don't work.
                $result = $result.subst( / '<TMPL_VAR NAME=' \w+ '>' /,
                                         $value );
            }
        }

        # Also need to check whether some parameters went unused during the
        # substitution. This might be best to do here, or in param(), I don't
        # know. Probably in param, with the allowed parameters pre-cached.
        # It's a little bit tricky, though, once you take <TEMPL_LOOP> into
        # account. Need to think about that.
        return $result;
    }
}
