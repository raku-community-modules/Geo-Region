unit class Geo::Region;

has @!includes;
has @!excludes;
has $!children;
has $!parents;
has $!countries;

submethod BUILD (:$include = (), :$exclude = ()) {
    @!includes = $include.map: { coerce_region($_) };
    @!excludes = $exclude.map: { coerce_region($_) };
}

sub set(@parts) {
    Map.new: @parts.map: { $_ => $_ with .Str }
}

my constant %children_of =
    # regions of subregions
  '001' => set(<002 009 019 142 150>),
  '002' => set(<011 014 015 017 018>),
  '003' => set(<013 021 029>),
  '009' => set(<053 054 057 061 QO>),
  '019' => set(<003 005 013 021 029 419>),
  '142' => set(<030 034 035 143 145>),
  '150' => set(<039 151 154 155 EU>),
  '419' => set(<005 013 029>),
    # regions of countries and territories
  '005' => set(<AR BO BR CL CO EC FK GF GY PE PY SR UY VE>),
  '011' => set(<BF BJ CI CV GH GM GN GW LR ML MR NE NG SH SL SN TG>),
  '013' => set(<BZ CR GT HN MX NI PA SV>),
  '014' => set(<BI DJ ER ET KE KM MG MU MW MZ RE RW SC SO TZ UG YT ZM ZW>),
  '015' => set(<DZ EA EG EH IC LY MA SD SS TN>),
  '017' => set(<AO CD CF CG CM GA GQ ST TD ZR>),
  '018' => set(<BW LS NA SZ ZA>),
  '021' => set(<BM CA GL PM US>),
  '029' => set(<AG AI AN AW BB BL BQ BS CU CW DM DO GD GP HT JM KN KY LC MF MQ MS PR SX TC TT VC VG VI>),
  '030' => set(<CN HK JP KP KR MN MO TW>),
  '034' => set(<AF BD BT IN IR LK MV NP PK>),
  '035' => set(<BN BU ID KH LA MM MY PH SG TH TL TP VN>),
  '039' => set(<AD AL BA CS ES GI GR HR IT ME MK MT PT RS SI SM VA XK YU>),
  '053' => set(<AU NF NZ>),
  '054' => set(<FJ NC PG SB VU>),
  '057' => set(<FM GU KI MH MP NR PW>),
  '061' => set(<AS CK NU PF PN TK TO TV WF WS>),
  '143' => set(<KG KZ TJ TM UZ>),
  '145' => set(<AE AM AZ BH CY GE IL IQ JO KW LB NT OM PS QA SA SY TR YD YE>),
  '151' => set(<BG BY CZ HU MD PL RO RU SK SU UA>),
  '154' => set(<AX DK EE FI FO GB GG IE IM IS JE LT LV NO SE SJ>),
  '155' => set(<AT BE CH DD DE FR FX LI LU MC NL>),
  'EU'  => set(<AT BE BG CY CZ DE DK EE ES FI FR GB GR HR HU IE IT LT LU LV MT NL PL PT RO SE SI SK>),
  'QO'  => set(<AC AQ BV CC CP CX DG GS HM IO TA TF UM>),
;

# codes excluded from country list due to being deprecated or grouping container
my constant $noncountries = set <AN BU CS DD FX NT SU TP YD YU ZR EU QO>;

# deprecated aliases
my constant %alias_of = :QU<EU>, :UK<GB>;

sub coerce_region ($region) {
    return $region.fmt('%03d')
        if $region ~~ /^ <[0..9]>+ $/;

    %alias_of{$region.uc} // $region.uc;
}

method !children () {
    $!children //= do {
        my sub build_children (@regions) {
            @regions.map({
                $^region,
                %children_of{$^region}:exists
                    ?? build_children(%children_of{$^region}.keys)
                    !! ()
            }).flat;
        }
        
        build_children(@!includes) (-) build_children(@!excludes);
    };

    $!children
}

method !parents () {
    $!parents //= do {
        my sub build_parents (@regions) {
            @regions.map({
                $^region,
                build_parents(%children_of.grep( *.value ∋ $^region )».key)
            }).flat.eager;
        }

        my %count;
        set build_parents(@!includes).grep: {
            ++%count{$^parent} == @!includes
        }
    }

    $!parents
}

method contains ($region) {
    self!children ∋ coerce_region($region)
}

method is-within ($region) {
    self!parents ∋ coerce_region($region)
}

method countries () {
    $!countries //= self!children.keys.grep({
        /<[A..Z]>/ && $_ ∉ $noncountries
    }).sort.cache;

    $!countries.values
}

=begin pod

=head1 NAME

Geo::Region - Geographical regions and groupings using UN M.49 and CLDR data

=head1 VERSION

This document describes Geo::Region for Raku, built with Unicode CLDR v26.

=head1 SYNOPSIS

=begin code :lang<raku>

use Geo::Region;
use Geo::Region::Enum;

$amer = Geo::Region.new(include => Region::Americas);

$emea = Geo::Region.new(
    include => (Region::Europe, Region::WesternAsia, Region::Africa)
);

$apac = Geo::Region.new(
    include => (Region::Asia, Region::Oceania),
    exclude => Region::WesternAsia,
);

if $amer.contains($country) {
    # country is in the Americas (US, MX, BR, etc.)
}
elsif $emea.contains($country) {
    # country is in Europe, the Middle East, and Africa (FR, SA, ZW, etc.)
}
elsif $apac.contains($country) {
    # country is in Asia-Pacific (JP, TH, AU, etc.)
}

=end code

=head1 DESCRIPTION

The C<Geo::Region> class is used to create geographical regions and
groupings of subregions and countries. Default regional groupings are
provided using the
L<Unicode CLDR v26 Territory Containment|https://unicode.org/cldr/charts/26/supplemental/territory_containment_un_m_49.html>
data, which is an extension of the United Nations
L<UN M.49 (Rev.3)|https://unstats.un.org/unsd/methods/m49/m49regin.htm>
standard.

=head2 Regions

Regions and subregions are represented with UN M.49 region codes,
such as B<419> for Latin America and B<035> for Southeast Asia.
Either the official format using a three-digit C<0>-padded string
like C<'035'> or an integer like C<35> may be used with this class.
Note when using the C<0>-padded format that it must be quoted as
a string so as not to be treated as on octal literal.

The CLDR also adds two additional two-letter region codes which are
supported: B<EU> for the European Union and B<QO> for Outlying
Oceania. These region codes are all available as enumerations in
L<Geo::Region::Enum>.

=head2 Countries

Countries and territories are represented with ISO 3166-1 alpha-2
country codes, such as B<JP> for Japan and B<AQ> for Antarctica,
and are case insensitive.  Unlike with region codes, the three-digit
forms of country codes are not currently supported, nor are
three-letter codes. The deprecated code B<UK> for the United Kingdom
is supported as an alias of the official code B<GB>.

=head2 Constructor

The C<new> class method is used to construct a Geo::Region object
along with the C<include> argument and optional C<exclude> argument.

=head3 include

Accepts either a single region code or an array reference of region or country
codes to be included in the resulting custom region.

=begin code :lang<raku>

# countries in the European Union (EU)
Geo::Region.new(include => Region::EuropeanUnion);

# countries in Asia (142) plus Russia (RU)
Geo::Region.new(include => (Region::Asia, Country::Russia));

=end code

=head3 exclude

Accepts values in the same format as C<include>. This can be used
to exclude countries or subregions from a region.

=begin code :lang<raku>

# countries in Europe (150) which are not in the European Union (EU)
Geo::Region.new(
  include => Region::Europe,
  exclude => Region::EuropeanUnion,
);

=end code

=head2 Methods

=head3 contains

Given a country or region code, determines if the region represented
by the Geo::Region instance contains it.

=begin code :lang<raku>

if $region.contains($country) {

=end code

=head3 is-within

Given a region code, determines if all the countries and regions
represented by the Geo::Region instance are within it.

=begin code :lang<raku>

if $subregion.is-within($region) {

=end code

=head3 countries

Returns a list of country codes of the countries within the region
represented by the Geo::Region instance.

=begin code :lang<raku>

for $region.countries -> $country {

=end code

=head1 SEE ALSO

=item L<Unicode CLDR: UN M.49 Territory
Containment|http://unicode.org/cldr/charts/26/supplemental/territory_containment_un_m_49.html>
=item L<United Nations: UN M.49 Standard Country, Area, & Region
Codes|http://unstats.un.org/unsd/methods/m49/m49regin.htm>

=head1 AUTHOR

Nova Patch

=head1 COPYRIGHT AND LICENSE

Copyright 2014 - 2018 Nova Patch

Copyright 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under
the same terms as Raku itself.

=end pod

# vim: expandtab shiftwidth=4
