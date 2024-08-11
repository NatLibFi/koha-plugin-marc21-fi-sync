package Koha::Plugin::Fi::NatLib::Marc21Sync::App::Defaults;
use Modern::Perl; use utf8; use open qw(:utf8);

our $CONFIGURATION = [

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

];

1;
