use v6;

class HTML::Template {

    has $.filename;
    has %!params;

    method param( Pair $param ) {
        %!params{$param.key} = $param.value;
    }

    method output() {
        # RAKUDO: Poor man's catch.
        my $worked = False;
        my $template;
        try {
            $template = slurp( $.filename );
            $worked = True;
        }
        die "Could not open $.filename" if !$worked;
        return self.substitute($template);
    }

    method substitute($text is rw) {
        while ( $text ~~ / '<TMPL_VAR NAME=' (<alnum>+) '>' / ) {
            my $key = $0;
            my $value = %!params{$key}
              // die "$key is defined in the template but undefined in source";

            # RAKUDO: Dotty methods don't work. '.=' would be nice here.
            $text = $text.subst( / '<TMPL_VAR NAME=' <alnum>+ '>' /, $value );
        }

        # Also need to check whether some parameters went unused during the
        # substitution. This might be best to do here, or in param(), I don't
        # know. Probably in param, with the allowed parameters pre-cached.
        # It's a little bit tricky, though, once you take <TEMPL_LOOP> into
        # account. Need to think about that.
        return $text;
    }
}
