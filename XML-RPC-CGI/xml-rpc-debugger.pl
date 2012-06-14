#!perl

use strict;
use CGI;

my $cgi = new CGI;

my $url = $cgi->param('url');
my $method = $cgi->param('method');
my $params = $cgi->param('params');

my $response;
if ($url && $method) {
	my $xml = qq~<?xml version="1.0"?>
<methodCall>
<methodName>$method</methodName>
$params
</methodCall>~;
	
	
	# Create a user agent object
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	$ua->agent("XML-Debugger/0.1 ");
	
	# Create a request
	my $req = HTTP::Request->new(POST => $url);
	$req->content_type('text/xml');
	$req->content_length(length($xml));
	$req->content($xml);
	
	# Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	# Check the outcome of the response
	if ($res->is_success) {
	    $response = $res->content;
	}
	else {
	    $response = "Error: ".$res->status_line;
	}
}

unless ($params) {
	$params = "<params></params>";
}

print $cgi->header( -type => 'text/html', charset => 'UTF-8');

print qq~<html>
<head>
	<title>Andi's simple RPC-XML Debugger</title>
</head>
<body>
<h1>Andis simple XML-RPC Debugger</h1>
<h3>URL:</h3>
<form action="tests.pl">
	<input name="url" type="text" size="60" maxlength="100" value="$url">
	<br/>
	<h3>Method:</h3>
	<input name="method" type="text" size="30" maxlength="30" value="$method">
	<br/>
	<h3>Params:</h3>
	<textarea name="params" rows="10" cols="50">$params</textarea>
	<br/>
	<input type="submit">
</form>
<p>
<h3>Response:</h3>
<textarea rows="50" cols="100">
$response
</textarea>
</p>
</body>
</html>~;