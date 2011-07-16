use v6;
use Plackdo::Middleware::Static;

my $data_root = './';
my $skins_root = './';

# TODO move all this into November::App?
use November;
use November::Config;
use Text::Markup::Wiki::MediaWiki;

my $c = November::Config.new(
    markup => Text::Markup::Wiki::MediaWiki.new(),
    skin   => 'CleanAndSoft'
);
my November $wiki = November.new(
    config => $c,
);


my $app = sub (%env) {
    $wiki.handle_request(%env);
}

Plackdo::Middleware::Static.new(
    root => $skins_root,
    # TODO This path doesn't get stripped from PATH_INFO before
    # App::File gets it -- seems like it should be?
    path => rx{^'/skins/'},
).wrap($app);

# vim:set ft=perl6:
