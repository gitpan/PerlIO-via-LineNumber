package PerlIO::via::LineNumber;

# Set the version info
# Make sure we do things by the book from now on

$VERSION = '0.01';
use strict;

# Set default initial line number
# Set default format
# Set default increment

my $line = 1;
my $format = '%4d %s';
my $increment = 1;

# Satisfy -require-

1;

#-----------------------------------------------------------------------

# Class methods

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default initial line number
# OUT: 1 current default initial line number

sub line {

# Set new default initial line number if one specified
# Return current default initial line number

   $line = $_[1] if @_ >1;
   $line;
} #line

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default format
# OUT: 1 current default format

sub format {

# Set new default format if one specified
# Return current default format

   $format = $_[1] if @_ >1;
   $format;
} #format

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default increment and default line number
# OUT: 1 current default increment

sub increment {

# Set new default increment if one specified
# Return current default increment

   $line = $increment = $_[1] if @_ >1;
   $increment;
} #increment

#-----------------------------------------------------------------------

# Subroutines for standard Perl features

#-----------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

# Die now if strange mode
# Create the object with the right fields

#    die "Can only read or write with line numbers" unless $_[1] =~ m#^[rw]$#;
    bless {line => $line, format => $format, increment => $increment},$_[0];
} #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 decoded string

sub FILL {

# If there is a line to be read from the handle
#  Obtain the current line number
#  Increment the remembered line number
#  Return with prefixed line number
# Return indicating end reached

    if (defined( my $line = readline( $_[1] ) )) {
	my $number = $_[0]->{'line'};
	$_[0]->{'line'} += $_[0]->{'increment'};
        return sprintf( $_[0]->{'format'},$number,$line );
    }
    undef;
} #FILL

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

# Obtain local copies of format, line number and increment
# For all of the lines in this bunch (includes delimiter at end)
#  Return with error if print failed
#  Increment the line number
# Return total number of octets handled

    my ($format,$increment) = @{$_[0]}{qw(format increment)};
    foreach (split( m#(?<=$/)#,$_[1] )) {
        return -1
	 unless print {$_[2]} sprintf( $format,$_[0]->{'line'},$_ );
	$_[0]->{'line'} += $increment;
    }
    length( $_[1] );
} #WRITE

#-----------------------------------------------------------------------
#  IN: class for which to import

sub import {

# Obtain the parameters
# Loop for all the value pairs specified

    my ($class,%param) = @_;
    $class->$_( $param{$_} ) foreach keys %param;
} #import

#-----------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::LineNumber - PerlIO layer for prefixing line numbers

=head1 SYNOPSIS

 use PerlIO::via::LineNumber;
 PerlIO::via::LineNumber->line( 1 );
 PerlIO::via::LineNumber->format( '%4d %s' );
 PerlIO::via::LineNumber->increment( 1 );

 use PerlIO::via::LineNumber line => 1, format => '%4d %s', increment => 1;

 open( my $in,'<:via(LineNumber)','file.ln' )
  or die "Can't open file.ln for reading: $!\n";
 
 open( my $out,'>:via(LineNumber)','file.ln' )
  or die "Can't open file.ln for writing: $!\n";

=head1 DESCRIPTION

This module implements a PerlIO layer that prefixes line numbers on input
B<and> on output.  It is intended as a development tool only, but may have
uses outside of development.

=head1 CLASS METHODS

The following class methods allow you to alter certain characteristics of
the line numbering process.  Ordinarily, you would expect these to be
specified as parameters during the process of opening a file.  Unfortunately,
it is not yet possible to pass parameters with the PerlIO::via module.

Therefore an approach with class methods was chosen.  Class methods that can
also be called as key-value pairs in the C<use> statement.

Please note that the new value of the class methods that are specified, only
apply to the file handles that are opened (or to which the layer is assigned
using C<binmode()>) B<after> they have been changed.

=head2 line

 use PerlIO::via::LineNumber line => 1;
 
 PerlIO::via::LineNumber->line( 1 );
 my $line = PerlIO::via::LineNumber->line;

The class method "line" returns the initial line number that will be used for
adding line numbers.  The optional input parameter specifies the initial line
number that will be used for any files that are opened in the future.  The
default is 1.

=head2 format

 use PerlIO::via::LineNumber format => '%4d %s';
 
 PerlIO::via::LineNumber->format( '%4d %s' );
 my $format = PerlIO::via::LineNumber->format;

The class method "format" returns the format that will be used for adding
line numbers.  The optional input parameter specifies the format that will
be used for any files that are opened in the future.  The default is '%4d %s'.

=head2 increment

 use PerlIO::via::LineNumber increment => 1;
 
 PerlIO::via::LineNumber->increment( 1 );
 my $increment = PerlIO::via::LineNumber->increment;

The class method "increment" returns the increment that will be used for
adding line numbers.  The optional input parameter specifies the increment
that will be used for any files that are opened in the future.  Setting the
increment will also cause the L<line> to be set to the same value.  The
default is 1.

=head1 EXAMPLES

Here are some examples, some may even be useful.

=head2 Write line numbers to a file

The following code creates a file handle that prefixes linenumbers while
writing to a file.

 use PerlIO::via::LineNumber;
 open( my $out,'>via(LineNumber)','numbered' ) or die $!;
 print $out <<EOD;
 These lines with
 text will have
 line numbers
 prefixed
 automagically.
 EOD

will end up as

    1 These lines with
    2 text will have
    3 line numbers
    4 prefixed
    5 automagically.

in the file called "numbered".

=head2 BASICfy filter

A script that adds linenumbers to a file in good old BASIC style.

 #!/usr/bin/perl
 use PerlIO::via::LineNumber format => '%04d %s', increment => 10;
 binmode( STDIN,':via(LineNumber)' ); # could also be STDOUT
 print while <STDIN>;

would output the following when called upon itself:

 0010 #!/usr/bin/perl
 0020 use PerlIO::via::LineNumber format => '%04d %s', increment => 10;
 0030 binmode( STDIN,':via(LineNumber)' );
 0040 print while <STDIN>;

=head1 SEE ALSO

L<PerlIO::via> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
