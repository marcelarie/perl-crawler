#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::Util qw(trim);

plugin 'AutoReload';

use Mojo::UserAgent;

# Fine grained response handling (dies on connection errors)
my $ua = Mojo::UserAgent->new;

# Render template "index.html.ep" from the DATA section
get '/' => sub ($c) {

    # if    ( $res->is_success )  { say $res->body }
    # elsif ( $res->is_error )    { say $res->message }
    # elsif ( $res->code == 301 ) { say $res->headers->location . 301 }
    # else                        { say 'Whatever...' }

    my $crypto_url = 'https://coinpare.io/';
    my $res        = $ua->get($crypto_url)->result;

    my @coins =
      $res->dom->find('td.coinName a')->map('text')->map( sub { s/(\t)|(\n)|(\r)//gr } );

    $c->render( json => { coins => @coins } );
};

app->start;
__DATA__

@@ index.html.ep
% my $url = url_for 'title';
<html>
    <body>$res</body>
</html>
