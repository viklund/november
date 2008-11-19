use v6;

use Test;
plan 5;

use Dispatcher;

my $d = Dispatcher.new;

my @rules =  
    ['foo'],        { "A" },
    /\d+/,          { "B" },
    ['foo', 'bar'], { "C" },
    'her'|'boo',    { "D" };

is($d.add_rules(@rules), 4, "add list of rules (right value)");

is($d.dispatch(['foo']), "A", "Dispatch rule ['foo']");
is($d.dispatch(['123']), "B", "Dispatch rule /\d+/");
is($d.dispatch(['foo', 'bar']), "C", "Dispatch ['foo', 'bar']");
is($d.dispatch(['boo']), "D", "Dispatch ['boo']");

# vim:ft=perl6
