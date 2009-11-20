package SQL::Dialects::AnyData;

use vars qw($VERSION);
$VERSION = '1.22';

sub get_config {
return <<EOC;
[VALID COMMANDS]
CREATE
DROP
SELECT
INSERT
UPDATE
DELETE

[VALID OPTIONS]
SELECT_MULTIPLE_TABLES
SELECT_AGGREGATE_FUNCTIONS

[VALID COMPARISON OPERATORS]
=
<>
<
<=
>
>=
LIKE
NOT LIKE
CLIKE
NOT CLIKE
RLIKE
NOT RLIKE
IS
IS NOT
IN
NOT IN
BETWEEN
NOT BETWEEN

[VALID DATA TYPES]
CHAR
VARCHAR
REAL
INT
INTEGER
BLOB
TEXT

[RESERVED WORDS]
INTEGERVAL
STRING
REALVAL
IDENT
NULLVAL
PARAM
OPERATOR
IS
AND
OR
ERROR
INSERT
UPDATE
SELECT
DELETE
DROP
CREATE
ALL
DISTINCT
WHERE
ORDER
ASC
DESC
FROM
INTO
BY
VALUES
SET
NOT
TABLE
CHAR
VARCHAR
REAL
INTEGER
PRIMARY
KEY
BLOB
TEXT
EOC
}
1;

=pod

=head1 NAME

SQL::Dialects::AnyData

=head1 SYNOPSIS

  use SQL::Dialects::AnyData;
  $config = SQL::Dialects::ANSI->get_config();

=head1 DESCRIPTION

This package provides the necessary configuration for AnyData SQL.

=head1 FUNCTIONS

=head2 get_config

Returns the configuration for AnyData SQL. The configuration is delivered in
ini-style:

  [VALID COMMANDS]
  ...

  [VALID OPTIONS]
  ...

  [VALID COMPARISON OPERATORS]
  ...

  [VALID DATA TYPES]
  ...

  [RESERVED WORDS]
  ...

=cut
