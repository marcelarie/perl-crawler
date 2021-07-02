#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::Util qw(trim);

plugin 'AutoReload';

use Mojo::UserAgent;

# Fine grained response handling (dies on connection errors)
my $ua = Mojo::UserAgent->new;

sub get_cryptos {
    my ( $page, ) = @_;

    my $crypto_url = 'https://coinpare.io/?cP=';
    my $res        = $ua->get( $crypto_url . $page )->result;

    if    ( $res->is_error )    { say $res->message }
    elsif ( $res->code == 301 ) { say $res->headers->location . 301 }

    my @names =
      $res->dom->find('td.coinName a')->map('text')
      ->map( sub { s/(\t)|(\n)|(\r)//gr } );

    my @prices = $res->dom->find('td.tPriceW')->map('text')
      ->map( sub { s/(\t)|(\n)|(\r)//gr } );

    my @market_cap = $res->dom->find('td.tMcapW')->map('text')
      ->map( sub { s/(\t)|(\n)|(\r)//gr } );

    my %hash        = ();
    my $current_max = 100 * $page;

    sub extract_current_crypto {
        my ( $crypto_pos, @list ) = @_;
        return $list[0]->[$crypto_pos];
    }

    for ( 0 .. 99 ) {
        $hash{ $_ + $current_max - 99 } = {
            name       => extract_current_crypto( $_, @names ),
            to_dollar  => extract_current_crypto( $_, @prices ),
            market_cap => extract_current_crypto( $_, @market_cap )
        };
    }

    return %hash;
}
get '/' => sub ($c) {
    my %result = get_cryptos(1);
    $c->render( json => {%result} );
};

get '/:page' => sub ($c) {
    my $page   = $c->stash('page');
    my %result = get_cryptos($page);
    $c->render( json => {%result} );
};

app->start;

# __DATA__

# @@ index.html.ep
# % my $url = url_for 'title';
# <html>
# <body>$res</body>
# </html>
