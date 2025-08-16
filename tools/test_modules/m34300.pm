#!/usr/bin/env perl

##
## Author......: See docs/credits.txt
## License.....: MIT
##

## checkout m13400.pm keepass1


# Pseudocode:
# 1. sha256(sha256(password=masterkey)||keyfile) = argon.in
# 2. argon2(salt=transformseed, password=argon2.in) = argon2.out
# 2. sha512(masterseed||argon2.out||0x01) = final
# 3. sha512(0xFFFFFFFFFFFFFFFF||final) = out
# 4. hmac_sha256(init=out, data=header) = header_hmac
# 5. compare header_hmac to hash

# variables in hash
# 0. signature
# 1. keepassDB version
# 2. iterations
# 3. KDF UUID
# 4. memoryUsageInBytes
# 5. Argon version
# 6. parallelism
# 7. masterseed
# 8. transformseed (salt)
# 9. header
# 10. headerhmac (digest)
# optional:
# 11. 1
# 12. 64 keyfile length
# 13. keyfile

use strict;
use warnings;

use MIME::Base64  qw (decode_base64 encode_base64);
use Crypt::Argon2 qw (argon2_raw);

sub module_constraints { [[0, 256], [32, 32], [-1, -1], [-1, -1], [-1, -1]] }

sub module_generate_hash
{
  my $word  = shift;
  my $masterseed  = shift;
  my $transformseed  = shift;
  my $header  = shift;

  my $kdf_uuid  = shift // (("argon2d", "ef636ddf"), ("argon2id", "9e298b19"))[random_number (0, 1)];
  my $m     = shift // (1 << random_number (22, 28)); #memory usage (in bytes?? TODO check)
  my $t     = shift // random_number (1, 8); #iterations
  my $p     = shift // random_number (1, 8); #parallelism
  my $len   = shift // random_number (1, 2) * 16;

  my $masterseed_bin = pack ("H*", $masterseed);
  my $transformseed_bin = pack ("H*", $transformseed);
  my $header_bin = pack ("H*", $header);

  my $digest_bin = argon2_raw ($kdf_uuid[0], $word, $salt_bin, $t, $m . "k", $p, $len);

#   my $salt_base64   = encode_base64 ($salt_bin,   ""); $salt_base64   =~ s/=+$//;
#   my $digest_base64 = encode_base64 ($digest_bin, ""); $digest_base64 =~ s/=+$//;

#   my $hash = sprintf ('$%s$v=19$m=%d,t=%d,p=%d$%s$%s', $sign, $m, $t, $p, $salt_base64, $digest_base64);

# $keepass$*4*2*ef636ddf*67108864*19*2*e4e48422ecb07da38401597150a7326fdd1519007b28c306c6e7418fb8ed29cb*af527945ec56bbb37f84ef85093735b689139f46c8003f82cad269837eb69d5f*03d9a29a67fb4bb500000400021000000031c1f2e6bf714350be5805216afc5aff0304000000010000000420000000e4e48422ecb07da38401597150a7326fdd1519007b28c306c6e7418fb8ed29cb0b8b00000000014205000000245555494410000000ef636ddf8c29444b91f7a9a403e30a0c040100000056040000001300000005010000004908000000020000000000000005010000004d080000000000000400000000040100000050040000000200000042010000005320000000af527945ec56bbb37f84ef85093735b689139f46c8003f82cad269837eb69d5f000710000000257fccc1e57ecdea03bbc06aab7cd13200040000000d0a0d0a*63249b86a7539e2bbdbf0ac7f196d460e781e221d1c580d4c718dcc1493eefa9
  my $hash = sprintf ('$keepass$*4*%d*%s*%d*19*%d*%s", $t, $kdf_uuid[1], $m, $p, $masterseed, $transformseed); #(dbversion), iterations, kdf_uuid, memoryusage, (argon2 version), parallelism, masterseed, transformseed

  return $hash;
}

sub module_verify_hash
{
  my $line = shift;

  my $idx = index ($line, ':');

  return unless $idx >= 0;

  my $hash = substr ($line, 0, $idx);
  my $word = substr ($line, $idx + 1);

  return unless ((substr ($hash, 0,  9) eq '$argon2d$')
              || (substr ($hash, 0,  9) eq '$argon2i$')
              || (substr ($hash, 0, 10) eq '$argon2id$'));

  my (undef, $signature, $version, $config, $salt, $digest) = split '\$', $hash;

  return unless defined $signature;
  return unless defined $version;
  return unless defined $config;
  return unless defined $salt;
  return unless defined $digest;

  my ($m_config, $t_config, $p_config) = split ("\,", $config);

  return unless ($version eq "v=19");

  my $m = (split ("=", $m_config))[1];
  my $t = (split ("=", $t_config))[1];
  my $p = (split ("=", $p_config))[1];

  $salt   = decode_base64 ($salt);
  $digest = decode_base64 ($digest);

  my $word_packed = pack_if_HEX_notation ($word);

  my $new_hash = module_generate_hash ($word_packed, unpack ("H*", $salt), $signature, $m, $t, $p, length ($digest));

  return ($new_hash, $word);
}

1;
