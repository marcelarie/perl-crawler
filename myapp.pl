#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::Util qw(trim);
use Mojo::Cache;

plugin 'AutoReload';

use Mojo::UserAgent;

# Fine grained response handling (dies on connection errors)
my $ua = Mojo::UserAgent->new;

sub get_cryptos {
    my ( $page, ) = @_;

    my @result = ();

    for ( 1 .. $page ) {

        my $crypto_url = 'https://coinpare.io/?cP=';
        my $res        = $ua->get( $crypto_url . $_ )->result;

        if    ( $res->is_error )    { say $res->message }
        elsif ( $res->code == 301 ) { say $res->headers->location . 301 }

        my @names =
          $res->dom->find('td.coinName a')->map('text')
          ->map( sub { s/(\t)|(\n)|(\r)//gr } );

        my @prices = $res->dom->find('td.tPriceW')->map('text')
          ->map( sub { s/(\t)|(\n)|(\r)//gr } );

        my @market_cap = $res->dom->find('td.tMcapW')->map('text')
          ->map( sub { s/(\t)|(\n)|(\r)//gr } );

        sub extract_current_crypto {
            my ( $crypto_pos, @list ) = @_;
            return $list[0]->[$crypto_pos];
        }

        my $current_max = 100 * $_;
        print("Retriving top $current_max cryptos. \n");

        for ( 0 .. 99 ) {
            my $position = $_ + $current_max - 99;
            push(
                @result,
                {
                    rank       => $position,
                    name       => extract_current_crypto( $_, @names ),
                    to_dollar  => extract_current_crypto( $_, @prices ),
                    market_cap => extract_current_crypto( $_, @market_cap )
                }
            );
        }
    }
    return @result;
}

# ENDPOINTS:
get '/' => sub ($c) {
    my @result = get_cryptos(1);
    $c->render( json => [@result] );
};

get '/:page' => sub ($c) {
    my $page   = $c->stash('page');
    my @result = get_cryptos($page);
    $c->render( json => [@result] );
};

app->start;
