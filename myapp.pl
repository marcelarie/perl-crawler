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

    my $crypto_url = 'https://coinpare.io/?cP=';
    my $page       = 1;
    my $res        = $ua->get( $crypto_url . $page )->result;

    my @names =
      $res->dom->find('td.coinName a')->map('text')
      ->map( sub { s/(\t)|(\n)|(\r)//gr } );

    my @prices = $res->dom->find('td.tPriceW')->map('text')
      ->map( sub { s/(\t)|(\n)|(\r)//gr } );

    my %hash = ();
    for ( 0 .. 99 ) {
        $hash{ $_ + 1 } =
          { name => @names[0]->[$_], price_in_dollar => @prices[0]->[$_] };
    }

    $c->render( json => {%hash} );
};

app->start;
__DATA__

@@ index.html.ep
% my $url = url_for 'title';
<html>
    <body>$res</body>
</html>
