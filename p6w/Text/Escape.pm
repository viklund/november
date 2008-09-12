use Impatience;

sub escape($str, $how) {
    # RAKUDO: .lc not emplemented yet
    #my $m = $how.lc;
    my $m = $how;
    return $str if $m eq 'none' | 'NONE';
    return escape_str($str, &escape_html_char) if $m eq 'html' | 'HTML';
    return escape_str($str, &escape_uri_char ) if $m eq 'url' | 'uri' | 'URL' | 'URI';
    die "Don't know how to escape format '$how' yet";
}

sub escape_html_char($c) {
    my %escapes = (
        '<'     => '&lt;',
        '>'     => '&gt;',
        '&'     => '&amp;',
        '"'     => '&quot;',
    );
    %escapes{$c} // $c;
}

sub escape_uri_char($c) {
    my $allowed = 'abcdefghijklmnopqrstuvwxyz'
                ~ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                ~ '0123456789'
                ~ '-_.!~*\'()';
    return $c if defined $allowed.index($c);
    return sprintf('%%%x', ord($c));

}

sub escape_str($str, $callback) {
    my $result = '';
    for 0 .. ($str.chars -1 ) -> $index {
        $result ~= $callback($str.substr($index, 1));
    }
    $result;
}

