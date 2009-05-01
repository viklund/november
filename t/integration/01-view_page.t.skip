use v6;

use Test;
use November;
use Test::CGI;
use Config;
use URI;

my @markups = < Text::Markup::Wiki::Minimal Text::Markup::Wiki::MediaWiki >;
my @skins   = < Autumn CleanAndSoft >;

my %gets    = {
    #''                  =>  'View main page',
    '/view/Main_Page'   =>  'View specific page',
    '/view/Snrsdfda'    =>  'View unexisting page',
    '/in'               =>  'Log in page',
    '/out'              =>  'Log out page',
    '/recent'           =>  'Recent changes',
    '/all'              =>  'All pages',
    '/all?tag=november' =>  'All pages, specific tag',
};

plan @markups * @skins * %gets;

my $uri = URI.new();
my $cgi = Test::CGI.new( uri => $uri );
for @markups X @skins -> $m, $s {
    my $c = Config.new( markup => $m, skin => $s );
    my $w = November.new( config => $c );
    $w.init;
    for %gets.kv -> $page, $description {
        $uri.init( 'http://testserver' ~ $page );
        $cgi.parse_params( $page );
        lives_ok( { $w.handle_request( $cgi ) }, "$m, $s, $description" );
    }
}

# vim:ft=perl6
