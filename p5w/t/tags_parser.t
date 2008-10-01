use Test::More tests => 8;
use November;

my $tf = \&November::tags_parse;

my @to_parse = (    
    [ 'foo',
      ['foo'] ],
    [ 'foo,bar',
      ['foo', 'bar'] ],
    [ 'foo, bar',
      ['foo', 'bar'] ],
    [ 'foo, bar ,her',
      ['foo', 'bar', 'her'] ],
    [ "foo\n",
      ['foo'] ],
    [ 'foo , bar    , her',
      ['foo', 'bar', 'her'] ],
    [ 'Foo',
      ['foo'] ],
    [ 'foo, BAR',
      ['foo', 'bar'] ],
);

for (@to_parse) {
    my ($in, $result) = @$_;
    my $comment =  'Parse tags: ' . $in; 
    $comment =~ s/\n/\\n/;
    is_deeply( $tf->($in), $result, $comment  );
}
