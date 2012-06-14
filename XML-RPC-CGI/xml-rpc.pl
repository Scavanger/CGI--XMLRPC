#!perl -w

BEGIN{
	push (@INC, , "./Modules")
}

use strict;
use CGI::Carp qw(fatalsToBrowser);
use CGI::XMLRPC;    

# Debug!
my $xml = qq~<?xml version="1.0"?>
<methodCall>
	<methodName>doSomething</methodName>
		<params>
			<param>
         		<value><i4>41</i4></value>
       		</param>
       		<param>
         		<value><string>Hello</string></value>
       		</param>
       		<param>
       			<struct>
				   <member>
				      <name>lowerBound</name>
				      <value><i4>18</i4></value>
				   </member>
				   <member>
				      <name>upperBound</name>
				      <value><i4>139</i4></value>
				   </member>
				</struct>
       		</param>
       		<param>
       			<array>
				   <data>
				      <value><i4>12</i4></value>
				      <value><string>Egypt</string></value>
				      <value><boolean>0</boolean></value>
				      <value><i4>-31</i4></value>
				      <value>
					      <array>
					      	<data>
						      	<value><boolean>1</boolean></value>
						      	<value><string>Noch einer!</string></value>
					      	</data>
					      </array>
				      </value>
				    </data>
				   </array>
       		</param>
      </params>
</methodCall>~; 

my $xmlrpc = CGI::XMLRPC->new(\&doSomething, \&doSomethingElse);
$xmlrpc->receive(useXMLRPCdatatypes =>1, xml => $xml);


sub doSomething {
	
	my @params =  @_;
	
	my $string = "Hellö";
	
	if (scalar(@params) != 0)	{
		return \@params;
	} else {
		return [
						CGI::XMLRPC::string->new("Bla"), 
						CGI::XMLRPC::boolean->new('false'),
					{
						'First' 	=> CGI::XMLRPC::string->new("A String"),
						'Second'	=> CGI::XMLRPC::int->new(6)
					},
					[
						CGI::XMLRPC::i4->new(42), 
						CGI::XMLRPC::string->new("Malvin"), 
						CGI::XMLRPC::boolean->new('True')
					]
				  ];
		}
	
	
}

sub doSomethingElse {
	#return CGI::XMLRPC::i4->new(3);
}

