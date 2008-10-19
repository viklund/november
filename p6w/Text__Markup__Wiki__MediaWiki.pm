use v6;

# RAKUDO: Calling methods in many-jointed classes doesn't work (#59928)
class Text__Markup__Wiki__MediaWiki {

    method format($text, :$link_maker) {
        return $text;
    }
}

# vim:ft=perl6
