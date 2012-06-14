package CGI::XMLRPC;

use strict;

use vars qw($ERROR_CODE $ERROR);

$ERROR_CODE = q{};
$ERROR = q{};


sub new {
	my $package = shift;
	my $self = {};
	
	# Class Property
	$self->{funcTable} = {@_} ;
	
	bless ($self, $package);
	return $self;
}

# Remove!
sub test {
	
	#CGI::XMLRPC->setError (1, "Error!!!!!");
	
	my $self = shift;
	
	my $class = ref($self);
    $class =~ s/.*://;
	
	my $funcName = shift; 
	
	
	my $funcRef = $self->{funcTable}{$funcName} or CGI::XMLRPC->setError(1, "Unknown function: $funcName");
	
	if (ref $funcRef eq 'CODE') {
		&{$funcRef}();
	} else {
		 CGI::XMLRPC->setError(2, "Internal Error: Can not execue function.");
	}

}

# Static

sub setError 
{
	my $self = shift;
	
	$CGI::XMLRPC::ERROR_CODE = shift; 
	$CGI::XMLRPC::ERROR = shift; 
}

# Data Classes - match XML-RPC Specs

# Base Class for all Datatypes
package CGI::XMLRPC::datatypeBase;

use strict;

sub getType {
	my $self = shift;
	my $class = ref $self || $self;
    $class =~ s/.*://;

    return $class;
}


# Base Class for base types
package CGI::XMLRPC::simpleTypeBase;

use strict;
use base 'CGI::XMLRPC::datatypeBase';
use Scalar::Util 'reftype'; 

sub new {
	my $package = shift;
	my $val = shift;
	
	if ($package->getType eq 'simpleTypeBase') { 
		CGI::XMLRPC->setError(4, 'Cannot instantiate BaseClass');
		return;
	}
	
	if (ref $val eq 'SCALAR') {
		$val = ${$val};
	} elsif (ref $val) {
		CGI::XMLRPC->setError(5, 'Cannot instantiate from a non scalar reference');
	}

	bless \$val, $package;	
}

sub value {
	my $self = shift;
	
	if (!ref $self) {
		CGI::XMLRPC->setError(6, 'No static Method!');
	}
	
	return ${$self};
}

package CGI::XMLRPC::i4;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase'; 

sub new {
	my $self = shift;
	my $val = shift;
	
	# Make sure we have valid 32bit Integer
	if ($val =~ /^[+-]?\d+\z/ && $val <= 2147483647	&& $val >= -2147483648) {
		$self->SUPER::new($val);
	} else {
		CGI::XMLRPC->setError(7, '$val is not a valid Integer.');
	}
}

package CGI::XMLRPC::double;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase';

sub new {
	my $self = shift;
	my $val = shift;
	
	if ($val =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i && $val <= 1e31 && $val >= -1e37) {
		$self->SUPER::new($val);
	} else {
		CGI::XMLRPC->setError(7, '$val is not a valid double.');
	}
}

package CGI::XMLRPC::boolean;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase';

sub new {
	my $self = shift;
	my $val = shift;
	
	if ($val =~ /true|1/i) {
		$self->SUPER::new(1);
	} elsif ($val =~ /false|0/i) {
		$self->SUPER::new(0);
	} else {
		CGI::XMLRPC->setError(7, '$val is not a valid boolean. Value must be True, False, 1 or 0');
	}
	
}

package CGI::XMLRPC::string;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase';

package CGI::XMLRPC::dateTime;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase';

sub new { 
	my $self = shift;
	my $val = shift;
	
	# Try to convert from a Unix time (Integer)
	if ($val =~ /^[+-]?\d+\z/) {
		$self->SUPER::new($self->toISO8601($val));
	} elsif ($val =~ /^\d{8}T(\d{2}:){2}\d{2}$/) { # Already a ISO8601 date?
		$self->SUPER::new($val);
	} else {
		CGI::XMLRPC->setError(7, '$val is not a valid dateTime. Value must be a unix time or a valid XML-RPC ISO8601 date.');
	}
}

# Convert to XML-RPC's IS08607 format
sub toISO8601 {
	my $self = shift;
	my $time = shift; 
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);
	
	return sprintf("%04d%02d%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
	
}

package CGI::XMLRPC::base64;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase'; 

sub new {
	my $self = shift;
	my $val = shift;
	
	if ($val =~ /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/) { 
		$self->SUPER::new($val);
	} else {
		CGI::XMLRPC->setError(7, ' Value is not a valid base64 encoded string'); 
	}
}



1;