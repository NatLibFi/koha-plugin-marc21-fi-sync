package Koha::Plugin::Fi::NatLib::Marc21Sync::App::Interface;
use Modern::Perl; use utf8; use open qw(:utf8);


## ----------------------------------------
## Plugin interface ADD BUTTON ON BIBLIO
## ----------------------------------------

sub intra_biblio_tbbutton {
    my ( $self ) = @_;

    return q|
        <a class="btn btn-default btn-sm" onclick="alert('Peace and long life');">
          <i class="fa fa-hand-spock" aria-hidden="true"></i>
          Live long and prosper
        </a>
    |;
}

1;
