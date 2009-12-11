use v6;

use Text::Markup::Wiki::MediaWiki;

class November::Config {
    has $.server_root = '';
    has $.web_root    = '';
    has $.skin        = 'CleanAndSoft';
    has $.markup      = Text::Markup::Wiki::MediaWiki.new;

    method template_path {
        my $str = $!server_root ~ 'skins/' ~ $!skin ~ '/';
        return $str;
    }

    method userfile_path {
        my $str = $!server_root ~ 'data/users';
        return $str;
    }
}

# vim:ft=perl6
