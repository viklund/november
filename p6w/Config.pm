use v6;
class Config {
    has $.server_root = '/home/johan/Devel/november/p6w/';
    has $.web_root    = '';
    has $.skin        = 'CleanAndSoft';
    has $.markup      = 'Text::Markup::Wiki::MediaWiki';

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
