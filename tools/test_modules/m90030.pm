#!/usr/bin/env perl

##
## Author......: See docs/credits.txt
## License.....: MIT
##

use strict;
use warnings;
use Math::BigInt;

sub module_constraints { [[0, 256], [-1, -1], [0, 32], [-1, -1], [0, 32]] }

sub wrapping_mul
{
  my $a = shift;
  my $b = shift;

  # 2**64
  my $width = Math::BigInt->new("0x10000000000000000");

  return ($a * $b)->bmod($width);
}

sub murmurhash64a_32
{
  use integer;

  my $word = shift;
  my $seed = 0;

  # https://gitlab.com/lschwiderski/vt2_bundle_unpacker/-/blob/master/src/murmur/murmurhash64.rs
  # 'm' and 'r' are mixing constants generated offline.
  # They're not really 'magic', they just happen to work well.

  my $m = Math::BigInt->new("0xc6a4a7935bd1e995");
  #my $m = 0xc6a4a7935bd1e995;
  my $r = 47;

  my @chars = unpack ("C*", $word);
  my $len = length $word;

  my $hash = $seed ^ wrapping_mul ($len, $m);

  my $endpos = $len - ($len & 7);
  my $i;

  for ($i = 0; $i < $endpos; $i += 8)
  {
    my $c0 = $chars[$i + 0];
    my $c1 = $chars[$i + 1];
    my $c2 = $chars[$i + 2];
    my $c3 = $chars[$i + 3];
    my $c4 = $chars[$i + 4];
    my $c5 = $chars[$i + 5];
    my $c6 = $chars[$i + 6];
    my $c7 = $chars[$i + 7];

    my $k = ($c0 <<  0)
          | ($c1 <<  8)
          | ($c2 << 16)
          | ($c3 << 24)
          | ($c4 << 32)
          | ($c5 << 40)
          | ($c6 << 48)
          | ($c7 << 56);

    $k = wrapping_mul ($k, $m);
    $k ^= $k >> $r;
    $k = wrapping_mul ($k, $m);

    $hash ^= $k;
    $hash = wrapping_mul ($hash, $m);
  }

  my $overflow = $len & 7;

  if ($overflow == 7)
  {
    $hash ^= $chars[$i + 6] << 48;
  }
  if ($overflow >= 6)
  {
    $hash ^= $chars[$i + 5] << 40;
  }
  if ($overflow >= 5)
  {
    $hash ^= $chars[$i + 4] << 32;
  }
  if ($overflow >= 4)
  {
    $hash ^= $chars[$i + 3] << 24;
  }
  if ($overflow >= 3)
  {
    $hash ^= $chars[$i + 2] << 16;
  }
  if ($overflow >= 2)
  {
    $hash ^= $chars[$i + 1] << 8;
  }
  if ($overflow >= 1)
  {
    $hash ^= $chars[$i + 0] << 0;
  }

  if ($overflow > 0)
  {
    $hash = wrapping_mul ($hash, $m);
  }

  $hash ^= $hash >> $r;
  $hash = wrapping_mul ($hash, $m);
  $hash ^= $hash >> $r;

  # use only high 32 bits from hash
  $hash = $hash >> 32;

  return $hash;
}

sub module_generate_hash
{
  my $word = shift;

  my $digest = murmurhash64a_32 ($word);

  $digest = unpack ("H*", pack ("L>", $digest));

  my $hash = sprintf ("%s", $digest);

  return $hash;
}

sub module_verify_hash
{
  my $line = shift;

  my ($hash, $word) = split (':', $line, 2);

  return unless defined $hash;
  return unless defined $word;

  return unless length $hash == 8;

  return unless ($hash =~ m/^[0-9a-fA-F]{8}$/);

  my $word_packed = pack_if_HEX_notation ($word);

  my $new_hash = module_generate_hash ($word_packed);

  return ($new_hash, $word);
}

1;
