% Copyright (c)2013 YAMAMOTO Takashi,
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
% OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
% LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
% OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
% SUCH DAMAGE.

-record(ether, {dst, src, type}).
-record(arp, {hrd, pro, hln, pln, op, sha, spa, tha, tpa}).
-record(revarp, {hrd, pro, hln, pln, op, sha, spa, tha, tpa}).
-record(ip, {version, ihl, tos, total_length, id, df, mf, offset, ttl,
        protocol, checksum, src, dst, options}).
-record(ipv6, {version, traffic_class, flow_label, payload_length, next_header,
        hop_limit, src, dst}).
-record(icmp, {type, code, checksum, data}).
-record(tcp, {src_port, dst_port, seqno = 0, ackno = 0, data_offset = 0,
              urg = 0, ack = 0, psh = 0, rst = 0, syn = 0, fin = 0, window = 0,
              checksum, urgent_pointer = 0, options = <<>>}).
