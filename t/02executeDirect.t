#!/usr/bin/perl -w
$| = 1;
use strict;
use lib qw' ./ ./t ';
use SQLtest;
use Test::More tests => 57;
use Params::Util qw(_INSTANCE);
my $DEBUG;

eval { $parser = SQL::Parser->new() };
ok( !$@, '$parser->new' );
$parser->{PrintError} = 0;
$parser->{RaiseError} = 1;
for my $sql (<DATA>)
{
    my $stmt;
    eval { $stmt = SQL::Statement->new( $sql, $parser ) };
    ok( !$@, '$stmt->new' );
    cmp_ok( $stmt->command,           'eq', 'SELECT', '$stmt->command' );
    cmp_ok( scalar( $stmt->params ),  '==', 1,        '$stmt->params' );
    cmp_ok( $stmt->tables(1)->name(), 'eq', 'c',      '$stmt->tables' );
    ok( defined( _INSTANCE( $stmt->where(),         'SQL::Statement::Operation::And' ) ),   '$stmt->where()->op' );
    ok( defined( _INSTANCE( $stmt->where()->{LEFT}, 'SQL::Statement::Operation::Equal' ) ), '$stmt->where()->left' );
    ok( defined( _INSTANCE( $stmt->where()->{LEFT}->{LEFT}, 'SQL::Statement::ColumnValue' ) ),
        '$stmt->where()->left->left' );
    ok( defined( _INSTANCE( $stmt->where()->{LEFT}->{RIGHT}, 'SQL::Statement::Placeholder' ) ),
        '$stmt->where()->left->right' );
    cmp_ok( $stmt->limit(),  '==', 2, '$stmt->limit' );
    cmp_ok( $stmt->offset(), '==', 5, '$stmt->offset' );

    next unless $DEBUG;
    printf "Command      %s\n", $stmt->command();
    printf "Num Pholders %s\n", scalar $stmt->params();
    printf "Columns      %s\n", join ',', map { $_->name } $stmt->columns();
    printf "Tables       %s\n", join ',', $stmt->tables();
    printf "Where op     %s\n", join ',', $stmt->where->op();
    printf "Limit        %s\n", $stmt->limit();
    printf "Offset       %s\n", $stmt->offset;
    printf "Order Cols   %s\n", join ',', map { $_->column } $stmt->order();
}
my $stmt = SQL::Statement->new( "INSERT a VALUES(3,7)", $parser );
cmp_ok( scalar( $stmt->row_values() ),  '==', 1, '$stmt->row_values()' );
cmp_ok( scalar( $stmt->row_values(0) ), '==', 2, '$stmt->row_values(0)' );
cmp_ok( scalar( $stmt->row_values( 0, 1 ) )->{value}, '==', 7, '$stmt->row_values(0,1)' );
cmp_ok( ref( $parser->structure ), 'eq', 'HASH',   'structure' );
cmp_ok( $parser->command(),        'eq', 'INSERT', 'command' );
ok( SQL::Statement->new( "SELECT DISTINCT c1 FROM tbl", $parser ), 'distinct' );
my $cache = {};

for my $sql (
    split /\n/,
    "   CREATE TABLE a (b INT, c CHAR)
    INSERT INTO a VALUES(1,'abc')
    INSERT INTO a VALUES(2,'efg')
    INSERT INTO a VALUES(3,'hij')
    INSERT INTO a VALUES(4,'klm')
    INSERT INTO a VALUES(5,'nmo')
    INSERT INTO a VALUES(6,'pqr')
    INSERT INTO a VALUES(7,'stu')
    INSERT INTO a VALUES(8,'vwx')
    INSERT INTO a VALUES(9,'yz')
    SELECT b,c FROM a WHERE c LIKE '%b%' ORDER BY c DESC"
            )
{
    # print "<$sql>\n";
    $stmt = SQL::Statement->new( $sql, $parser );
    eval { $stmt->execute($cache) };
    warn $@ if $@;
    ok( !$@, '$stmt->execute "' . $sql . '" (' . $stmt->command() . ')' );
    next unless( $stmt->command() eq 'SELECT' );
    cmp_ok( ref( $stmt->where_hash ), 'eq', 'HASH', '$stmt->where_hash' );
    cmp_ok( $stmt->columns(0)->name(), 'eq', 'b', '$stmt->columns' );
    cmp_ok( join( '', $stmt->column_names() ), 'eq', 'bc', '$stmt->column_names' );
    cmp_ok( $stmt->order(0)->{desc}, 'eq', 'DESC', '$stmt->order' );

    while ( my $row = $stmt->fetch )
    {
        cmp_ok( $row->[0], '==', 1, '$stmt->fetch' );
    }
}

my %gen_inbtw = (
                  q{SELECT b,c FROM a WHERE b IN (2,3,5,7)}      => '2^efg^3^hij^5^nmo^7^stu',
                  q{SELECT b,c FROM a WHERE b NOT IN (2,3,5,7)}  => '1^abc^4^klm^6^pqr^8^vwx^9^yz',
                  q{SELECT b,c FROM a WHERE NOT b IN (2,3,5,7)}  => '1^abc^4^klm^6^pqr^8^vwx^9^yz',
                  q{SELECT b,c FROM a WHERE b BETWEEN (5,7)}     => '5^nmo^6^pqr^7^stu',
                  q{SELECT b,c FROM a WHERE b NOT BETWEEN (5,7)} => '1^abc^2^efg^3^hij^4^klm^8^vwx^9^yz',
                  q{SELECT b,c FROM a WHERE NOT b BETWEEN (5,7)} => '1^abc^2^efg^3^hij^4^klm^8^vwx^9^yz',
                  q{SELECT b,c FROM a WHERE c IN ('abc','klm','pqr','vwx','yz')}     => '1^abc^4^klm^6^pqr^8^vwx^9^yz',
                  q{SELECT b,c FROM a WHERE c NOT IN ('abc','klm','pqr','vwx','yz')} => '2^efg^3^hij^5^nmo^7^stu',
                  q{SELECT b,c FROM a WHERE NOT c IN ('abc','klm','pqr','vwx','yz')} => '2^efg^3^hij^5^nmo^7^stu',
                  q{SELECT b,c FROM a WHERE c BETWEEN ('abc','nmo')}                 => '1^abc^2^efg^3^hij^4^klm^5^nmo',
                  q{SELECT b,c FROM a WHERE c NOT BETWEEN ('abc','nmo')}             => '6^pqr^7^stu^8^vwx^9^yz',
                  q{SELECT b,c FROM a WHERE NOT c BETWEEN ('abc','nmo')}             => '6^pqr^7^stu^8^vwx^9^yz',
                );

while ( my ( $sql, $result ) = each(%gen_inbtw) )
{
    $stmt = SQL::Statement->new( $sql, $parser );
    eval { $stmt->execute($cache) };
    warn $@ if $@;
    ok( !$@, '$stmt->execute "' . $sql . '" (' . $stmt->command . ')' );
    my @res;
    while ( my $row = $stmt->fetch )
    {
        push( @res, @{$row} );
    }
    is( $result, join( '^', @res ), $sql );
}
__DATA__
SELECT a FROM b JOIN c WHERE c=? AND e=7 ORDER BY f DESC LIMIT 5,2
