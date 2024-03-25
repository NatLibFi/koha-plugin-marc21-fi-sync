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
};


## ----------------------------------------
## Configuration screen values
## (each plugin should have a few)
## ----------------------------------------

our $configuration = [
    {   name => 'nightly_cron_enabled',
        type => 'checkbox',
        default => undef,
        name_display => 'Enable nightly sync cronjob for MARC21',
        description => 'this means plugin will sync at night all expected data, and import that into Frameworkds database',
    },
    {   name => 'download_set',
        type => 'textarea',
        default => "bib: 000 001-006 007 008 01X-04X 05X-08X 1XX 20X-24X 250-270 3XX 4XX 50X-53X 53X-58X 6XX 70X-75X 76X-78X 80X-830 841-88X 9XX\n"
                    ."aukt: 000 00X 01X-09X 1XX 2XX-3XX 4XX 5XX 64X 663-666 667-68X 7XX 8XX\n"
                    ."hold: 000 001-008 0XX 5XX-84X 852-856 853-855 863-865 866-868 876-878 88X\n",
        name_display => 'Dirs and files to download',
        description => "Subsections which will be downloaded from marc21.kansalliskirjasto.fi. This is special field, in frormat: <pre>dir1: files space separated\ndir2: files space separated</pre>for example line: <pre>bib: 001-006 007 008 01X-04X 05X-08X 1XX 20X-24X 250-270\n 3XX 4XX 50X-53X 53X-58X 6XX 70X-75X 76X-78X 80X-830 841-88X 9XX</pre>",
    },
    {   name => 'log_level',
        type => 'select',
        default => 1,
        name_display => 'Log level',
        description => 'Log level for plugin',
        options => [
            { value => 4, label => 'Debug'  },
            { value => 3, label => 'Notice' },
            { value => 2, label => 'Info'   },
            { value => 1, label => 'Warn'   },
            { value => 0, label => 'Error'  },
        ],
    },
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

sub cronjob_nightly { return shift->{app}->cronjob_nightly(@_); }

sub configure   { return shift->{app}->configure_plugin(@_); }
# sub report      { return shift->{app}->runtime_report_mode(@_); }
# sub tool        { return shift->{app}->runtime_tool_mode(@_); }
# sub intranet_js { return shift->{app}->runtime_intranet_js(@_); }

# sub intranet_catalog_biblio_enhancements_toolbar_button { return shift->{app}->intra_biblio_tbbutton(@_); }

# sub template_include_paths { my $self = shift; return [ $self->mbf_path('templates/includes') ]; }


## ----------------------------------------
## Predefined new method, no need to change
## ----------------------------------------

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
