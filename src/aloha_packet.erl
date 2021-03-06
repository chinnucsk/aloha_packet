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

-module(aloha_packet).
-export([encode_packet/1]).
-export([decode_packet/1, decode/3]).

-include("aloha_packet.hrl").

encode_packet(List) ->
    encode_packet(lists:reverse(List), <<>>).

encode_packet([], Acc) ->
    Acc;
encode_packet([H|Rest], Acc) ->
    encode_packet(Rest, encode(H, Rest, Acc)).

decode_packet(Data) ->
    decode_packet(ether, Data, []).

decode_packet(_Type, <<>>, Acc) ->
    lists:reverse(Acc);
decode_packet(Type, Data, Acc) ->
    {Rec, NextType, Rest} = decode(Type, Data, Acc),
    decode_packet(NextType, Rest, [Rec|Acc]).

decode(ether, Data, _Stack) ->
    <<Dst:6/bytes, Src:6/bytes, TypeInt:16, Rest/bytes>> = Data,
    Type = to_atom(ethertype, TypeInt),
    {#ether{dst=Dst, src=Src, type=Type}, Type, Rest};
decode(arp, Data, _Stack) ->
    decode_arp(Data);
decode(revarp, Data, _Stack) ->
    % compatible with arp
    Result = decode_arp(Data),
    setelement(1, Result, revarp);
decode(ip, Data, _Stack) ->
    <<Version:4, IHL:4, TOS:8, TotalLength:16,
      Id:16, _:1, DF:1, MF:1, Offset:13,
      TTL:8, ProtocolInt:8, _Checksum:16,
      Src:4/bytes, Dst:4/bytes, Rest/bytes>> = Data,
    HdrLen = IHL * 4,
    OptLen = HdrLen - 20,
    DataLen = TotalLength - OptLen - 20,
    <<Options:OptLen/bytes, Rest2:DataLen/bytes, _/bytes>> = Rest,
    Protocol = to_atom(ip_proto, ProtocolInt),
    <<CheckedData:HdrLen/bytes, _/bytes>> = Data,
    Checksum = case checksum(CheckedData) of
        0 -> good;
        _ -> bad
    end,
    {#ip{version=Version, ihl=IHL, tos=TOS, total_length=TotalLength,
     id=Id, df=DF, mf=MF, offset=Offset, ttl=TTL, protocol=Protocol,
     checksum=Checksum, src=Src, dst=Dst, options=Options}, Protocol, Rest2};
decode(icmp, Data, _Stack) ->
    <<Type:8, Code:8, _Checksum:16, Rest/bytes>> = Data,
    Checksum = case checksum(Data) of
        0 -> good;
        _ -> bad
    end,
    {#icmp{type=to_atom(icmp_type, Type), code=Code, checksum=Checksum,
           data=Rest}, bin, <<>>};
decode(ipv6, Data, _Stack) ->
    <<Version:4, TrafficClass:8, FlowLabel:20,
      PayloadLength:16, NextHeaderInt:8, HopLimit:8,
      Src:16/bytes, Dst:16/bytes, Rest/bytes>> = Data,
    NextHeader = to_atom(ip_proto, NextHeaderInt),
    {#ipv6{version=Version, traffic_class=TrafficClass,
     flow_label=FlowLabel, payload_length=PayloadLength,
     next_header=NextHeader, hop_limit=HopLimit, src=Src, dst=Dst},
     NextHeader, Rest};
decode(tcp, Data, Stack) ->
    <<SrcPort:16, DstPort:16,
      SeqNo:32,
      AckNo:32,
      DataOffset:4, _:6, URG:1, ACK:1, PSH:1, RST:1, SYN:1, FIN:1, Window:16,
      _Checksum:16, UrgentPointer:16,
      Rest/bytes>> = Data,
    OptLen = (DataOffset - 5) * 4,
    <<Options:OptLen/bytes, Rest2/bytes>> = Rest,
    Checksum = case Stack of
        [Ip|_] ->
            Phdr = phdr(Ip, DataOffset * 4 + size(Rest2)),
            case checksum(<<Phdr/bytes, Data/bytes>>) of
                0 -> good;
                _ -> bad
            end;
        _ ->
            unknown
    end,
    {#tcp{src_port=SrcPort, dst_port=DstPort,
               seqno=SeqNo, ackno=AckNo, data_offset=DataOffset,
               urg=URG, ack=ACK, psh=PSH, rst=RST, syn=SYN, fin=FIN,
               window=Window, checksum=Checksum, urgent_pointer=UrgentPointer,
               options=decode_tcp_option(Options)}, bin, Rest2};
decode(Type, Data, _Stack) ->
    {{Type, Data}, bin, <<>>}.

decode_arp(Data) ->
    <<Hrd:16, Pro:16, Hln:8, Pln:8, Op:16, Rest/bytes>> = Data,
    <<Sha:Hln/bytes, Spa:Pln/bytes, Tha:Hln/bytes, Tpa:Pln/bytes,
      Rest2/bytes>> = Rest,
    {#arp{hrd=Hrd, pro=to_atom(ethertype, Pro), hln=Hln, pln=Pln,
          op=to_atom(arp_op, Op), sha=Sha, spa=Spa, tha=Tha, tpa=Tpa},
     bin, Rest2}.

decode_tcp_option(Data) ->
    decode_tcp_option(Data, []).

decode_tcp_option(<<>>, Acc) ->
    lists:reverse(Acc);
decode_tcp_option(Data, Acc) ->
    <<KindInt:8, Rest/bytes>> = Data,
    Kind = to_atom(tcp_option, KindInt),
    decode_tcp_option(Kind, Rest, Acc).

decode_tcp_option(eol, _Data, Acc) ->
    decode_tcp_option(<<>>, [eol|Acc]);
decode_tcp_option(noop, Data, Acc) ->
    decode_tcp_option(Data, [noop|Acc]);
decode_tcp_option(mss, Data, Acc) ->
    <<4:8, Val:16, Rest/bytes>> = Data,
    decode_tcp_option(Rest, [{mss, Val}|Acc]);
decode_tcp_option(wscale, Data, Acc) ->
    <<3:8, Val:8, Rest/bytes>> = Data,
    decode_tcp_option(Rest, [{wscale, Val}|Acc]);
decode_tcp_option(sack_permitted, Data, Acc) ->
    <<2:8, Rest/bytes>> = Data,
    decode_tcp_option(Rest, [sack_permitted|Acc]);
decode_tcp_option(timestamp, Data, Acc) ->
    <<10:8, Val1:32, Val2:32, Rest/bytes>> = Data,
    decode_tcp_option(Rest, [{timestamp, Val1, Val2}|Acc]);
decode_tcp_option(Type, Data, Acc) ->
    <<Len:8, Rest/bytes>> = Data,
    <<Val:Len/bytes, Rest2/bytes>> = Rest,
    decode_tcp_option(Rest2, [{Type, Val}|Acc]).

encode(#ether{dst=Dst, src=Src, type=Type}, _Stack, Rest) ->
    TypeInt = to_int(ethertype, Type),
    Bin = <<Dst:6/bytes, Src:6/bytes, TypeInt:16, Rest/bytes>>,
    Size = size(Bin),
    Pad = max(60 - Size, 0),
    <<Bin/binary, 0:Pad/unit:8>>;
encode(#ip{version=Version, ihl=IHL, tos=TOS, total_length=_TotalLength,
     id=Id, df=DF, mf=MF, offset=Offset, ttl=TTL, protocol=Protocol,
     checksum=_Checksum, src=Src, dst=Dst, options=Options}, _Stack, Rest) ->
    ProtocolInt = to_int(ip_proto, Protocol),
    OptLen = size(Options),
    OptPadLen = (-OptLen) band 3,
    TotalLength = 20 + OptLen + OptPadLen + size(Rest),
    Checksum = checksum(<<Version:4, IHL:4, TOS:8, TotalLength:16,
      Id:16, 0:1, DF:1, MF:1, Offset:13,
      TTL:8, ProtocolInt:8, 0:16,
      Src:4/bytes, Dst:4/bytes, Options/bytes, 0:OptPadLen/unit:8>>),
    <<Version:4, IHL:4, TOS:8, TotalLength:16,
      Id:16, 0:1, DF:1, MF:1, Offset:13,
      TTL:8, ProtocolInt:8, Checksum:16,
      Src:4/bytes, Dst:4/bytes, Options/bytes, 0:OptPadLen/unit:8,
      Rest/bytes>>;
encode(#arp{hrd=Hrd, pro=Pro, hln=Hln, pln=Pln, op=Op,
       sha=Sha, spa=Spa, tha=Tha, tpa=Tpa}, _Stack, Rest) ->
    ProInt = to_int(ethertype, Pro),
    OpInt = to_int(arp_op, Op),
    <<Hrd:16, ProInt:16, Hln:8, Pln:8, OpInt:16,
      Sha:Hln/bytes, Spa:Pln/bytes, Tha:Hln/bytes, Tpa:Pln/bytes, Rest/bytes>>;
encode(#icmp{type=Type, code=Code, checksum=_Checksum, data=Data},
       _Stack, Rest) ->
    TypeInt = to_int(icmp_type, Type),
    Pkt = <<TypeInt:8, Code:8, 0:16, Data/bytes>>,
    Checksum = checksum(Pkt),
    <<TypeInt:8, Code:8, Checksum:16, Data/bytes, Rest/bytes>>;
encode(#tcp{src_port=SrcPort, dst_port=DstPort,
            seqno=SeqNo, ackno=AckNo, data_offset=_DataOffset,
            urg=URG, ack=ACK, psh=PSH, rst=RST, syn=SYN, fin=FIN,
            window=Window, checksum=_Checksum,
            urgent_pointer=UrgentPointer, options=OptionsTerm}, Stack, Rest) ->
    [Ip|_] = Stack,
    Options = encode_tcp_option(OptionsTerm),
    OptLen = size(Options),
    OptPadLen = (-OptLen) band 3,
    DataOffset = (OptLen + OptPadLen) div 4 + 5,
    Phdr = phdr(Ip, DataOffset * 4 + size(Rest)),
    Hdr = <<SrcPort:16, DstPort:16, SeqNo:32, AckNo:32,
      DataOffset:4, 0:6, URG:1, ACK:1, PSH:1, RST:1, SYN:1, FIN:1, Window:16,
      0:16, UrgentPointer:16, Options:OptLen/bytes, 0:OptPadLen/unit:8>>,
    Checksum = checksum(<<Phdr/bytes, Hdr/bytes, Rest/bytes>>),
    <<SrcPort:16, DstPort:16, SeqNo:32, AckNo:32,
      DataOffset:4, 0:6, URG:1, ACK:1, PSH:1, RST:1, SYN:1, FIN:1, Window:16,
      Checksum:16, UrgentPointer:16, Options:OptLen/bytes, 0:OptPadLen/unit:8,
      Rest/bytes>>;
encode({bin, Bin}, _Stack, Rest) ->
    <<Bin/bytes, Rest/bytes>>;
encode(Bin, _Stack, Rest) when is_binary(Bin) ->
    <<Bin/bytes, Rest/bytes>>.

encode_tcp_option(Bin) when is_binary(Bin) ->
    Bin;
encode_tcp_option(List) ->
    encode_tcp_option(List, []).

encode_tcp_option([], Acc) ->
    iolist_to_binary(lists:reverse(Acc));
encode_tcp_option([H|Rest], Acc) ->
    encode_tcp_option(H, Rest, Acc).

encode_tcp_option(eol, [], Acc) ->
    KindInt = to_int(tcp_option, eol),
    encode_tcp_option([], [<<KindInt:8>>|Acc]);
encode_tcp_option(noop, Rest, Acc) ->
    KindInt = to_int(tcp_option, noop),
    encode_tcp_option(Rest, [<<KindInt:8>>|Acc]);
encode_tcp_option({mss, Val}, Rest, Acc) ->
    encode_tcp_option(mss, 2, Val, Rest, Acc);
encode_tcp_option({wscale, Val}, Rest, Acc) ->
    encode_tcp_option(wscale, 1, Val, Rest, Acc);
encode_tcp_option(sack_permitted, Rest, Acc) ->
    encode_tcp_option(sack_permitted, 0, 0, Rest, Acc);
encode_tcp_option({timestamp, TSval, TSecr}, Rest, Acc) ->
    encode_tcp_option(timestamp, 8, <<TSval:32, TSecr:32>>, Rest, Acc).

encode_tcp_option(Kind, ValLen, Val, Rest, Acc) when is_binary(Val) ->
    KindInt = to_int(tcp_option, Kind),
    encode_tcp_option(Rest, [<<KindInt:8, (ValLen+2):8, Val/bytes>>|Acc]);
encode_tcp_option(Kind, ValLen, Val, Rest, Acc) ->
    encode_tcp_option(Kind, ValLen, <<Val:ValLen/unit:8>>, Rest, Acc).

phdr(#ip{src=Src, dst=Dst, protocol=Proto}, Len) ->
    ProtoInt = to_int(ip_proto, Proto),
    <<Src:4/bytes, Dst:4/bytes,
      0:8, ProtoInt:8, Len:16>>.

checksum(Bin) ->
    checksum_fold(checksum_add(Bin, 0)).

checksum_add(<<>>, Acc) ->
    Acc;
checksum_add(<<Byte:8>>, Acc) ->
    checksum_add(<<>>, Acc + (Byte bsl 8));
checksum_add(<<Word:16, Rest/bytes>>, Acc) ->
    checksum_add(Rest, Acc + Word).

checksum_fold(Sum) when Sum =< 16#ffff ->
    16#ffff - Sum;
checksum_fold(Sum) ->
    checksum_fold((Sum band 16#ffff) + (Sum bsr 16)).

to_int(Type, Enum) ->
    try
        aloha_enum:to_int(Type, Enum)
    catch
        throw:bad_enum ->
            Enum
    end.

to_atom(Type, Enum) ->
    try
        aloha_enum:to_atom(Type, Enum)
    catch
        throw:bad_enum ->
            Enum
    end.
