requires "Dancer2" => "0.166000";
requires "DBI"     => "1.634";
requires "Moose"   => "2.1604";

recommends "YAML"             => "0";
recommends "URL::Encode::XS"  => "0";
recommends "CGI::Deurl::XS"   => "0";
recommends "HTTP::Parser::XS" => "0";

on "test" => sub {
    requires "Test::More"            => "0";
    requires "Test::MockModule"      => "0.11";
    requires "HTTP::Request::Common" => "0";
};
