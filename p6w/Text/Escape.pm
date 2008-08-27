sub escape($str, $how) {
    my $m = $how.lc;
    return $str if $m eq 'none';
    return escape_str($str, &escape_html_char) if $m eq 'html';
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


sub escape_str($str, $callback) {
    my $result = '';
    for 0 .. ($str.chars -1 ) -> $index {
        $result ~= $callback($str.substr($index, 1));
    }
    $result;
}

