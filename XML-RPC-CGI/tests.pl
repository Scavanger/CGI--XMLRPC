#!perl

use strict;
use Scalar::Util 'reftype';

my $int = "-2147483649 cm";

if (isInt32($int) ){
	print "Integer";
}

my $scalar = \&doSomething;

my $reftype = ref $scalar;
my $refType2 = reftype($scalar);

my @arr = ("1", "2", "3");  
#my $funcName = "doSomething";

my $funcRef = \&doSomething;

my %funcTable = ( 
	'doSomething' 		=> \&doSomething,
	'doSomethingElse'	=> \&doSomethingElse
);
			
hashTest("1",  
	'doSomething' 		=> \&doSomething,
	'doSomethingElse'	=> \&doSomethingElse
);
			
refTest('doSomethingElse');

sub isInt32 {
	my $val = shift;
	
	if ($val =~ /^[+-]?\d+\z/ && $val <= 2147483647	&& $val >= -2147483648) {
		return 1;
	} else {
		return 0;
	}
}

sub hashTest {
	my $arg = shift;
	my %hash = @_;
	
	print ("!");
}

sub refTest {
	
	my $funcName = shift;
	my $funcRef = $funcTable{$funcName};
	
	if (ref $funcRef eq 'CODE') {
		&{$funcRef}();
	}
		
	#foreach (@_) {
	#	if (ref eq 'ARRAY') {
	#		print "Array";
	#	} elsif (ref eq 'CODE') {
	#		&{$_}();
	#	} 
	#}
}

sub doSomething {
	
	print "Hello!";
}

sub doSomethingElse {
	
	print "Servus!";
}