use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'tessa',
    AUTHOR              => q{Hunter McMillen <mcmillhj@gmail.com>},
    VERSION_FROM        => 'lib/tessa.pm',
    ABSTRACT            => 'tessa, an asset manager',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    MIN_PERL_VERSION => 5.18.2,
    PREREQ_PM => {
        'YAML'       => 0,
        'Dancer2'    => 0.166000,
        'DBI'        => 1.634,
	'Moose'      => 2.1604,
    },
    TEST_REQUIRES => {
	'Test::MockModule' => 0.11,
        'Test::More'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'tessa-*' },
);
