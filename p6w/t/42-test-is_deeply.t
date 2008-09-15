#!perl6
use Test;
plan 14;

ok( _is_deeply( {}, {} ), 'Two empty hashes' );
ok( _is_deeply( [], [] ), 'Two empty Array' );
nok( _is_deeply( {}, [] ), 'Empty Array and empty Hash' );
nok( _is_deeply( {foo => 'bar'}, {} ), 'Plain Hash and empty Hash' );
nok( _is_deeply( {foo => 'bar'}, [] ), 'Plain Hash and empty Array' );
nok( _is_deeply( ['foo'], {} ), 'Plain Array and empty Hash' );
nok( _is_deeply( ['foo'], [] ), 'Plain Array and empty Array' );

ok( _is_deeply( {foo => 'bar'}, {foo => 'bar'} ), 'Two equal plain hashes' );
nok( _is_deeply( {foo => 'bar'}, {foo => 'her'} ), 'Two not equal plain hashes' );
nok( _is_deeply( {foo => 'bar'}, {foo => 'her', bar => 'moo'} ), 'Two not equal hashes' );
nok( _is_deeply( {foo => 'bar'}, ['foo', 'her'] ), 'Hash and Array' );
ok( _is_deeply( {foo => 'bar', her => 'boo'},  {foo => 'bar', her => 'boo'} ), 'Two equal hashes with two key' );
nok( _is_deeply( {foo => 'bar', her => 'boo'},  {foo => 'bar', her => 'boooooh'} ), 'Two not equal hashes with two key' );
ok( _is_deeply( {key2 => ["val", undef]}, {key2 => ["val", undef]}), '{key2 => ["val", undef]}' );
