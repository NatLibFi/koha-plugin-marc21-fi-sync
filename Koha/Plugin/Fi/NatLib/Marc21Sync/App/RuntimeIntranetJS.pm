package Koha::Plugin::Fi::NatLib::Marc21Sync::App::RuntimeIntranetJS;
use Modern::Perl; use utf8; use open qw(:utf8);


## ----------------------------------------
## Plugin runtime Intranet JS
## ----------------------------------------

sub runtime_intranet_js {
    my ( $self ) = @_;

    return q|<script>

        $(function() {
            if (window.location.pathname == '/cgi-bin/koha/members/members-home.pl') {
                console.log('I should do some special here for only this page');
            } else if (window.location.pathname == '/cgi-bin/koha/circ/circulation.pl') {
                console.log('I should do some special here for only this page');
            } else{
                console.log('Do everything else for other pages');
            }
        });
    </script>|;
}

1;
