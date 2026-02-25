package Koha::Plugin::Fi::NatLib::Marc21Sync;
use Modern::Perl; use utf8; use open qw(:utf8);
use base qw(Koha::Plugins::Base);

use Koha::Plugin::Fi::NatLib::Marc21Sync::App;

use Koha::DateUtils ();


## ----------------------------------------
## Plugin description metadata
## ----------------------------------------

our $VERSION = "{VERSION}";
our $metadata = {
    name            => 'MARC21 Sync (FI)',
    author          => 'Kansalliskirjasto Koha Dev Team / Andrii, Slava, Petro',
    description     => 'Syncs MARC21 data for Koha instances from marc21.kansalliskirjasto.fi',
    homepage        => 'https://github.com/NatLibFi/koha-plugin-marc21-fi-sync',
    date_authored   => '2024-03-25',
    date_updated    => '1900-01-01',
    minimum_version => '23.1100000',
    maximum_version => undef,
    version         => $VERSION,
    default_method  => __PACKAGE__->can('tool') ? 'tool' : __PACKAGE__->can('report') ? 'report' : __PACKAGE__->can('configure') ? 'configure' : '',
};


## ----------------------------------------
## Configuration screen values
## (each plugin should have a few)
## ----------------------------------------

our $configuration = [
    @$Koha::Plugin::Fi::NatLib::Marc21Sync::App::Defaults::CONFIGURATION,
];


## ----------------------------------------
## Which methods we have acrive in our plugin
## ----------------------------------------
## just have it here declaured, but they then subcalled to App-> methods to have modularization.

## no critic (Subroutines::RequireArgUnpacking);

sub install   { my $self = shift; $self->{app}->preconfig($self); return $self->{app}->init_install_plugin(@_); }
sub uninstall { my $self = shift; $self->{app}->preconfig($self); return $self->{app}->init_uninstall_plugin(@_); }
sub upgrade   { my $self = shift; $self->{app}->preconfig($self);
    warn "--- PLUGIN: " . __PACKAGE__ . " upgrading now. ---\n";
    Koha::Caches->get_instance('plugins')->clear_from_cache($self->{app}{config_cache_key});
    my $dt = Koha::DateUtils::dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );
    $self->{app}->preconfig($self);
    return $self->{app}->init_upgrade_plugin(@_);
}
sub cronjob_nightly {
    my $app = shift->{app};
    # we will not do anything if nightly cron is not enabled, except trimming logs
    $app->trim_log();
    return
        unless $app->{config}{nightly_cron_enabled};

    $app->logf( 'INFO', "Nightly cronjob STARTED." );
    my $res = $app->cronjob_nightly(@_);
    $app->logf( 'INFO', "Nightly cronjob ENDED." );
    return $res;
}

sub configure   { return shift->{app}->configure_plugin(@_); }
# sub report      { return shift->{app}->runtime_report_mode(@_); }
# sub tool        { return shift->{app}->runtime_tool_mode(@_); }
# sub intranet_js { return shift->{app}->runtime_intranet_js(@_); }

# sub intranet_catalog_biblio_enhancements_toolbar_button { return shift->{app}->intra_biblio_tbbutton(@_); }


# Almost predefined, required for breadcrumbs to work,
# but unless you need extra include folders, add some here:
sub template_include_paths { my $self = shift; return [ $self->mbf_path('templates/includes') ]; }

## -----------------------------------------------
## Predefined new method below, no need to change
## -----------------------------------------------

sub new {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new({ %{$args//{}},
        metadata => { %$metadata, class => $class },
        app => Koha::Plugin::Fi::NatLib::Marc21Sync::App->new({ configuration => $configuration }),
    });
    $self->{app}->preconfig($self);
    return $self;
}

1;
