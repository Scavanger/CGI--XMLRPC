package CGI::XMLRPC;

use strict;
use XML::Simple;
use CGI;
use B qw(svref_2object);

use vars qw($ERROR_CODE $ERROR);

$ERROR_CODE = q{};
$ERROR = q{};


sub new {
	my $package = shift;
	my $self = {};
	# Class Propertys
	$self->{methods} = \@_;
	$self->{useXMLRPCdatatypes} = 0;
	$self->{cgi} = CGI->new();
	
	bless ($self, $package);
	return $self;
}

sub receive {
	my ($xmlStruct, $methodName, $funcRef, @params);

	my $self = shift;
	my $subParams = {@_};
	
	my $xmlString = $subParams->{xml} ? $subParams->{xml} : 0;
	$self->{useXMLRPCdatatypes} = $subParams->{useXMLRPCdatatypes} ? 1 : 0;
	
	eval {
		unless ($xmlString) {
			$xmlString = $self->{cgi}->param('POSTDATA'); 
		}
		
		unless (defined $xmlString) {
			CGI::XMLRPC->setError(10, 'No xml data.');
		}
		
		$xmlStruct = XMLin($xmlString, ForceArray => 1);
	};
	if ($@) {
		CGI::XMLRPC->setError(10, $@);
	}
	
	if (exists $xmlStruct->{methodName}) {
		$methodName = $xmlStruct->{methodName}[0];
	} else {
		CGI::XMLRPC->setError(11, 'No method specified or invalid XML');
	} 
	
	unless  (exists $xmlStruct->{params}) {
		CGI::XMLRPC->setError(12, 'Invalid params');
	}
	
	foreach my $param (@{$xmlStruct->{params}[0]->{param}}) {
		push (@params, $self->value($param));
	}
	
	my $found = 0;
	my $returnVal;
	foreach my $methodRef (@{$self->{methods}}) {
		my $subName = svref_2object($methodRef)->GV->NAME;
		if ($subName eq $methodName && ref $methodRef eq 'CODE' ) {
			eval {
				$returnVal = &{$methodRef}(@params);
			};
			if ($@) {
				CGI::XMLRPC->setError(20, $@);
			}
			
			$found = 1;
			last;
		}
	}
	
	unless ($found) {
		 CGI::XMLRPC->setError(2, 'Unknown method '.$methodName );
	}
	
	$self->reponse($returnVal);
}

sub reponse {
	my ($xmlDataStruct, $value, $cgi, $xmlout);
	my $self = shift;
	my $param = shift;
	
	if ($param) {
		eval {
			$value = $self->traverseStruct($param);
		};
		if ($@) {
			CGI::XMLRPC->setError(10, $@);
		}
		
		$xmlDataStruct = { params => [ 
										{ 
											param => [ $value ] 
										}
									  ]
						};
	} else {
		$xmlDataStruct = 0;
	}
	
	$xmlout = XMLout($xmlDataStruct, XMLDecl => '<?xml version="1.0"?>',  RootName => 'methodResponse', KeyAttr => [  ] );
	
	print $self->{cgi}->header( -type => 'text/xml', charset => 'UTF-8', contentlength => length($xmlout));
	print $xmlout;
}

# Building data structure for XML::Simple recursive
sub traverseStruct {
	my ($type);
	my $self = shift;
	my $value = shift;
	
	$type = ref $value;
	
	if ($type eq 'ARRAY') {
		my @arrayValues;
		foreach my $val (@{$value}) {
			push (@arrayValues, $self->traverseStruct($val));
		}
		return { array => [ 
						  	{ 
						  		data =>  [ @arrayValues ] 
						  	} 
						  ] 
		   	   };
	} elsif ($type eq 'HASH') {
		my (@hashMembers, $name, $val);
		while (($name, $val) = each (%{$value})) {
			my $val = { 
						name => [ $name ],
						%{$self->traverseStruct($val)}
									
								
					};
			push(@hashMembers, $val); 
		} 
		return { struct => [ 
								{
									member => [ @hashMembers ]
								}
							]
			   };
	} elsif ($type && $value->isa('CGI::XMLRPC::datatypeBase')) {
			return { value => [ 
								{ 
									$value->getType => [ $value->value ] 
								} 
							   ]
				   };
	} else {
		CGI::XMLRPC->setError(20, 'Unknown Datatype. Use CGI::XMLRPC datatypes.')
	}
}

sub value {
	my $self = shift;
	my $value = shift;
	
	unless (defined $value) {
		CGI::XMLRPC->setError(13, 'Invalid value');
	}
	
	my $type =  (keys(%{$value}))[0];
	
	if ($type eq 'value') {
		return $self->value($value->{$type}[0]);
	} elsif ($type eq 'array') {
		return $self->array($value->{$type}[0]->{data}[0]);
	} elsif ($type eq 'struct') {
		return $self->struct($value->{$type}[0]);
	} elsif (!$self->{useXMLRPCdatatypes}) {
		return $value->{$type}[0];
	} elsif ($type eq 'i4' || $type eq 'int') {
		return CGI::XMLRPC::i4->new($value->{$type}[0]);
	} elsif ($type eq 'string') {
		return CGI::XMLRPC::string->new($value->{$type}[0]);
	} elsif ($type eq 'boolean') {
		return CGI::XMLRPC::boolean->new($value->{$type}[0]);
	} elsif ($type eq 'double') {
		return CGI::XMLRPC::double->new($value->{$type}[0]);
	} elsif ($type eq 'dateTime.iso8601') {
		return CGI::XMLRPC::dateTime->new($value->{$type}[0]);
	} elsif ($type eq 'base64') {
		return CGI::XMLRPC::base64->new($value->{$type}[0]);
	} else {
		CGI::XMLRPC->setError(12, 'Unknown datatype '.$type);
	}
}

sub array {
	my @retArray;
	my $self = shift;
	my $array = shift;
	
	unless (defined $array) {
		CGI::XMLRPC->setError(13, 'Invalid array');
	}
	
	foreach my $value (@{$array->{value}}) {
		push(@retArray, $self->value($value));
	}
	
	return \@retArray;
	
}

# = Perl hash
sub struct {
	my %struct;
	my $self = shift;
	my $struct = shift;
	
	unless (defined $struct) {
		CGI::XMLRPC->setError(13, 'Invalid struct');
	}
	
	foreach my $member (@{$struct->{member}}) {
		my ($name, $value);
		
		$name = $member->{name}[0];
		$value = $self->value($member->{value}[0]);
		
		$struct{$name} = $value;
	}
	
	return \%struct;
}


# Static
sub setError 
{
	my ($xmlout, $cgi);
	my $self = shift;
	
	$CGI::XMLRPC::ERROR_CODE = shift; 
	$CGI::XMLRPC::ERROR = shift; 
		
	$xmlout = qq
~<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value>
            <int>$CGI::XMLRPC::ERROR_CODE</int>
          </value>
        </member>
        <member>
          <name>faultString</name>
          <value>
            <string>$CGI::XMLRPC::ERROR</string>
          </value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>~;
	
	$cgi = CGI->new();
	print $cgi->header( -type => 'text/xml', charset => 'UTF-8', contentlength => length($xmlout));
	print $xmlout;
	
	exit;
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
	my $self = shift;
	my $val = shift;
	
	if ($self->getType eq 'simpleTypeBase') { 
		CGI::XMLRPC->setError(4, 'Cannot instantiate BaseClass');
		return;
	}
	
	if (ref $val eq 'SCALAR' && $self->parse($val)) {
		$val = ${$val};
	} elsif (ref $val) {
		CGI::XMLRPC->setError(5, 'Cannot instantiate from a non scalar reference');
	}

	bless \$val, $self;	 
}

sub value {
	my $self = shift;
	
	unless (ref $self) {
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
		CGI::XMLRPC->setError(7, $val.' is not a valid Integer.');
	}
}

package CGI::XMLRPC::int;

use strict;
use base 'CGI::XMLRPC::i4'; 

package CGI::XMLRPC::double;

use strict;
use base 'CGI::XMLRPC::simpleTypeBase';

sub new {
	my $self = shift;
	my $val = shift;
	
	if ($val =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i && $val <= 1e31 && $val >= -1e37) {
		$self->SUPER::new($val);
	} else {
		CGI::XMLRPC->setError(7, $val.' is not a valid double.');
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
		CGI::XMLRPC->setError(7, $val.' is not a valid boolean. Value must be True, False, 1 or 0');
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
		CGI::XMLRPC->setError(7, $val.' is not a valid dateTime. Value must be a unix time or a valid XML-RPC ISO8601 date.');
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
		CGI::XMLRPC->setError(7, 'Value is not a valid base64 encoded string'); 
	}
}


1;