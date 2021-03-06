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

-module(aloha_packet_test).

-include("aloha_packet.hrl").

-include_lib("eunit/include/eunit.hrl").

tcp_bin() ->
    <<242,11,164,149,235,12,0,3,71,140,161,179,8,0,69,0,0,162,0,0,64,0,64,6,182,75,192,0,2,1,192,0,2,9,31,144,210,224,0,0,0,1,180,110,233,188,80,16,11,184,54,65,0,0,72,84,84,80,47,49,46,49,32,50,48,48,32,79,75,13,10,99,111,110,110,101,99,116,105,111,110,58,32,107,101,101,112,45,97,108,105,118,101,13,10,115,101,114,118,101,114,58,32,67,111,119,98,111,121,13,10,100,97,116,101,58,32,77,111,110,44,32,49,50,32,65,117,103,32,50,48,49,51,32,49,52,58,52,48,58,50,51,32,71,77,84,13,10,99,111,110,116,101,110,116,45,108,101,110,103,116,104,58,32,55,13,10,13,10,97,108,111,104,97,33,10>>.

tcp_term() ->
    [#ether{dst = <<242,11,164,149,235,12>>,
            src = <<0,3,71,140,161,179>>,
            type = ip},
     #ip{version = 4,ihl = 5,tos = 0,total_length = 162,id = 0,
         df = 1,mf = 0,offset = 0,ttl = 64,protocol = tcp,
         checksum = good,
         src = <<192,0,2,1>>,
         dst = <<192,0,2,9>>,
         options = <<>>},
     #tcp{src_port = 8080,dst_port = 53984,seqno = 1,
          ackno = 3027167676,data_offset = 5,urg = 0,ack = 1,psh = 0,
          rst = 0,syn = 0,fin = 0,window = 3000,checksum = good,
          urgent_pointer = 0,options = []},
     {bin,<<"HTTP/1.1 200 OK\r\nconnection: keep-alive\r\nserver: Cowboy\r\ndate: Mon, 12 Aug 2013 14:40:23 GMT\r\ncontent-length: 7\r\n\r\naloha!\n">>}].

tcp_bin2() ->
    <<0,3,71,140,161,179,142,17,145,26,179,75,8,0,69,0,0,64,0,0,64,0,64,6,182,174,192,0,2,8,192,0,2,1,226,97,31,144,218,159,58,11,0,0,0,0,176,2,128,0,27,86,0,0,2,4,5,180,1,3,3,3,4,2,1,1,1,1,8,10,0,0,0,1,0,0,0,0>>.

tcp_term2() ->
    [#ether{dst = <<0,3,71,140,161,179>>,
            src = <<142,17,145,26,179,75>>,
            type = ip},
     #ip{version = 4,ihl = 5,tos = 0,total_length = 64,id = 0,
         df = 1,mf = 0,offset = 0,ttl = 64,protocol = tcp,
         checksum = good,
         src = <<192,0,2,8>>,
         dst = <<192,0,2,1>>,
         options = <<>>},
     #tcp{src_port = 57953,dst_port = 8080,seqno = 3667868171,
          ackno = 0,data_offset = 11,urg = 0,ack = 0,psh = 0,rst = 0,
          syn = 1,fin = 0,window = 32768,checksum = good,
          urgent_pointer = 0,
          options = [{mss,1460},
                     noop, 
                     {wscale,3}, 
                     sack_permitted,
                     noop,noop,noop,noop,
                     {timestamp,1,0}]}].

arp_bin() ->
    <<242,11,164,149,235,12,0,3,71,140,161,179,8,6,0,1,8,0,6,4,0,2,0,3,71,140,161,179,192,0,2,1,242,11,164,149,235,12,192,0,2,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>.

arp_term() ->
    [#ether{dst = <<242,11,164,149,235,12>>,
            src = <<0,3,71,140,161,179>>,
            type = arp},
     #arp{hrd = 1,pro = ip,hln = 6,pln = 4,op = reply,
          sha = <<0,3,71,140,161,179>>,
          spa = <<192,0,2,1>>,
          tha = <<242,11,164,149,235,12>>,
          tpa = <<192,0,2,9>>},
     {bin,<<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>}].

icmp_bin() ->
    <<0,3,71,140,161,179,242,11,164,149,235,12,8,0,69,0,0,84,220,4,0,0,255,1,91,153,192,0,2,9,192,0,2,1,8,0,97,173,21,237,0,1,159,59,12,0,0,0,0,0,175,21,52,17,0,0,0,0,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,0,0,0,0,0,0,0,0>>.

icmp_term() ->
    [#ether{dst = <<0,3,71,140,161,179>>,
            src = <<242,11,164,149,235,12>>,
            type = ip},
     #ip{version = 4,ihl = 5,tos = 0,total_length = 84,
         id = 56324,df = 0,mf = 0,offset = 0,ttl = 255,
         protocol = icmp,checksum = good,
         src = <<192,0,2,9>>,
         dst = <<192,0,2,1>>,
         options = <<>>},
     #icmp{type = echo_request,code = 0,checksum = good,
           data = <<21,237,0,1,159,59,12,0,0,0,0,0,175,21,52,17,0,
                    0,0,0,16,17,18,19,20,21,22,23,24,25,26,27,28,
                    29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,
                    44,45,46,47,0,0,0,0,0,0,0,0>>}].

remove_pad(Packet) ->
    lists:keydelete(bin, 1, Packet).

tcp_decode_test() ->
    ?assertEqual(tcp_term(), aloha_packet:decode_packet(tcp_bin())).

tcp_encode_test() ->
    ?assertEqual(tcp_bin(), aloha_packet:encode_packet(tcp_term())).

tcp2_decode_test() ->
    ?assertEqual(tcp_term2(), aloha_packet:decode_packet(tcp_bin2())).

tcp2_encode_test() ->
    ?assertEqual(tcp_bin2(), aloha_packet:encode_packet(tcp_term2())).

arp_decode_test() ->
    ?assertEqual(arp_term(), aloha_packet:decode_packet(arp_bin())).

arp_encode_test() ->
    ?assertEqual(arp_bin(), aloha_packet:encode_packet(arp_term())).

icmp_decode_test() ->
    ?assertEqual(icmp_term(), aloha_packet:decode_packet(icmp_bin())).

icmp_encode_test() ->
    ?assertEqual(icmp_bin(), aloha_packet:encode_packet(icmp_term())).

ether_pad_test() ->
    ?assertEqual(arp_bin(), aloha_packet:encode_packet(remove_pad(arp_term()))).
