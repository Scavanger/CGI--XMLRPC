#!perl

BEGIN{
	push (@INC, , "./Modules")
}

#use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use CGI::XMLRPC;   

my $type = CGI::XMLRPC::simpleTypeBase->new(); 

my $cgi = new CGI;
print $cgi->header( -type => 'text/html', charset => 'UTF-8');

# Debug!
my $xml = qq~
<?xml version="1.0"?>
<methodCall>
<methodName>test</methodName>
<params>1</params>
</methodCall>
~; 
# Webserver
# my $xml    = $q->param('POSTDATA'); 

my $int = CGI::XMLRPC::boolean->new('True');

my $i = $int->value;

my $xmlrpc = CGI::XMLRPC->new(
	'doSomething' 		=> \&doSomething,
	'doSomethingElse'	=> \&doSomethingElse
); 

$isoDate = CGI::XMLRPC::dateTime->new(time);
$date = CGI::XMLRPC::dateTime->new('19980717T14:08:55');

$base64 = CGI::XMLRPC::base64->new('eW91IGNhbid0IHJlYWQgdGhpcyE=');

$xmlrpc->test('doSomething');

print "!";

sub doSomething {
	print "Hallo";
}

sub doSomethingElse {
	print "servus";
}



