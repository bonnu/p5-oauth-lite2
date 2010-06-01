package OAuth::Lite2::Formatter::XML;

use strict;
use warnings;

use base 'OAuth::Lite2::Formatter';
use Try::Tiny;
use XML::LibXML;
use OAuth::Lite2::Error;

sub name { "xml" }
sub type { "application/xml" }

sub format {
    my ($self, $hash) = @_;
    my $xml = '<?xml version="1.0" encoding="UTF-8"?>';
    $xml .= '<OAuth>';
    for my $key ( keys %$hash ) {
        $xml .= sprintf(q{<%s>%s</%s>},
            $key,
            $hash->{$key},
            $key);
    }
    $xml .= '</OAuth>';
    return $xml;
}

sub parse {
    my ($self, $xml) = @_;
    my $parser = XML::LibXML->new;
    my $doc;
    try {
        $doc = $parser->parse_string($xml);
    } catch {
        OAuth::Lite2::Error::InvalidFormat->throw(
            message => "Parse Error: " . $_);
    };
    my $root = $doc->documentElement();
    OAuth::Lite2::Error::InvalidFormat->throw(
        message => "<OAuth/> Element not found: " . $xml)
        unless $root->nodeName eq 'OAuth';
    my $hash = {};
    my @children = $root->childNodes();
    for my $child ( @children ) {
        next unless $child->nodeType == 1;
        my $key = $child->nodeName();
        next unless $key;
        my $value = $child->textContent() || '';
        $hash->{$key} = $value;
    }
    return $hash;
}

1;
