package Koha::Plugin::Fi::NatLib::Marc21Sync::App::RuntimeTool;
use Modern::Perl; use utf8; use open qw(:utf8);


## ----------------------------------------
## Plugin runtime TOOL phase
## ----------------------------------------

sub runtime_tool_mode {
    my ( $self, $args ) = @_;
    my $cgi = $self->{plugin}{cgi};

    $self->go_home();

    return;
}

1;
