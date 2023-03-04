riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
 
    xor a1, a1, a1
    xor a2, a2, a2

    addi a1, a1, 1
    addi a2, a2, 2

    la x1, fourteen
    sw a1, 0(x1)
    la x1, fifteen
    sw a2, 0(x1)

    la x1, onefourtwo
    sw a1, 0(x1)
    la x1, onefourthree
    sw a2, 0(x1)

    la x1, onetwoseven
    sw a1, 0(x1)
    la x1, twotwoseven
    sw a2, 0(x1)

    addi a1, a1, 2
    addi a2, a2, 2

    la x1, fourteen
    sw a1, 0(x1)
    la x1, fifteen
    sw a2, 0(x1)

    lw a1, onefourtwo

/*    lw  x1, threshold # X1 <- 0x40
    lui  x2, 2       # X2 <= 2
    lui  x3, 8     # X3 <= 8
    srli x2, x2, 12
    srli x3, x3, 12

    addi x4, x3, 4    # X4 <= X3 + 4

loop1:
    slli x3, x3, 1    # X3 <= X3 << 1
    xori x5, x2, 127  # X5 <= XOR (X2, 7b'1111111)
    addi x5, x5, 1    # X5 <= X5 + 1
    addi x4, x4, 4    # X4 <= X4 + 4

    bleu x4, x1, loop1   # Branch based on x4 and x1

    andi x6, x3, 64   # X6 <= X3 + 64

    auipc x7, 8         # X7 <= PC + 8
    lw x8, good         # X8 <= 0x600d600d
    la x10, result      # X10 <= Addr[result]
    sw x8, 0(x10)       # [Result] <= 0x600d600d
    lw x9, result       # X9 <= [Result]
    bne x8, x9, deadend # PC <= deadend if x8 != x9
*/
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.
/*
deadend:
    lw x8, bad     # X8 <= 0xdeadbeef{sim:/mp3_tb/dut/cache/datapath/way1/data[3]}

threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d*/

one:        .word 0x00000001
two:        .word 0x00000002
three:        .word 0x00000003
four:        .word 0x00000004
five:        .word 0x00000005
six:        .word 0x00000006
seven:        .word 0x00000007
eight:        .word 0x00000008
nine:        .word 0x00000009
ten:           .word 0x00000010
eleven:        .word 0x00000011
twelve:        .word 0x00000012
thirteen:        .word 0x00000013
fourteen:        .word 0x00000014
fifteen:        .word 0x00000015
sixteen:        .word 0x00000016
seventeen:        .word 0x00000017
eighteen:        .word 0x00000018
nineteen:        .word 0x00000019
twenty:        .word 0x00000020
twentyone:        .word 0x00000021
twentytwo:        .word 0x00000022
twentythree:        .word 0x00000023
twentyfour:        .word 0x00000024
twentyfive:        .word 0x00000025
twentysix:        .word 0x00000026
twentyseven:        .word 0x00000027
twentyeight:        .word 0x00000028
twentynine:        .word 0x00000029
thirty:        .word 0x00000030
thirtyone:        .word 0x00000031
thirtytwo:        .word 0x00000032
thirtythree:        .word 0x00000033
thirtyfour:        .word 0x00000034
thirtyfive:        .word 0x00000035
thirtysix:        .word 0x00000036
thirtyseven:        .word 0x00000037
thirtyeight:        .word 0x00000038
thirtynine:        .word 0x00000039
forty:              .word 0x00000040
fortyone:                .word 0x00000041
fortytwo:                .word 0x00000042
fortythree:              .word 0x00000043
fortyfour:               .word 0x00000044
fortyfive:               .word 0x00000045
fortysix:                .word 0x00000046
fortyseven:              .word 0x00000047
fortyeight:              .word 0x00000048
fortynine:               .word 0x00000049
fifty:                   .word 0x00000050
fiftyone:                .word 0x00000051
fiftytwo:                .word 0x00000052
fiftythree:              .word 0x00000053
fiftyfour:               .word 0x00000054
fiftyfive:               .word 0x00000055
fiftysix:                .word 0x00000056
fiftyseven:              .word 0x00000057
fiftyeight:              .word 0x00000058
fiftynine:               .word 0x00000059
sixty:                   .word 0x00000060
sixtyone:                .word 0x00000061
sixtytwo:                .word 0x00000062
sixtythree:              .word 0x00000063
sixtyfour:               .word 0x00000064
sixtyfive:               .word 0x00000065
sixtysix:                .word 0x00000066
sixtyseven:              .word 0x00000067
sixtyeight:              .word 0x00000068
sixtynine:               .word 0x00000069
seventy:                   .word 0x00000070
seventyone:                .word 0x00000071
seventytwo:                .word 0x00000072
seventythree:              .word 0x00000073
seventyfour:               .word 0x00000074
seventyfive:               .word 0x00000075
seventysix:                .word 0x00000076
seventyseven:              .word 0x00000077
seventyeight:              .word 0x00000078
seventynine:               .word 0x00000079
eighty:                   .word 0x00000080
eightyone:                .word 0x00000081
eightytwo:                .word 0x00000082
eightythree:              .word 0x00000083
eightyfour:               .word 0x00000084
eightyfive:               .word 0x00000085
eightysix:                .word 0x00000086
eightyseven:              .word 0x00000087
eightyeight:              .word 0x00000088
eightynine:               .word 0x00000089
ninety:                   .word 0x00000090
ninetyone:                .word 0x00000091
ninetytwo:                .word 0x00000092
ninetythree:              .word 0x00000093
ninetyfour:               .word 0x00000094
ninetyfive:               .word 0x00000095
ninetysix:                .word 0x00000096
ninetyseven:              .word 0x00000097
ninetyeight:              .word 0x00000098
ninetynine:               .word 0x00000099
oneo:                   .word 0x00000100
oneoone:                .word 0x00000101
oneotwo:                .word 0x00000102
oneothree:              .word 0x00000103
oneofour:               .word 0x00000104
oneofive:               .word 0x00000105
oneosix:                .word 0x00000106
oneoseven:              .word 0x00000107
oneoeight:              .word 0x00000108
oneonine:               .word 0x00000109
oneone:                   .word 0x00000110
oneoneone:                .word 0x00000111
oneonetwo:                .word 0x00000112
oneonethree:              .word 0x00000113
oneonefour:               .word 0x00000114
oneonefive:               .word 0x00000115
oneonesix:                .word 0x00000116
oneoneseven:              .word 0x00000117
oneoneeight:              .word 0x00000118
oneonenine:               .word 0x00000119
onetwo:                   .word 0x00000120
onetwoone:                .word 0x00000121
onetwotwo:                .word 0x00000122
onetwothree:              .word 0x00000123
onetwofour:               .word 0x00000124
onetwofive:               .word 0x00000125
onetwosix:                .word 0x00000126
onetwoseven:              .word 0x00000127
onetwoeight:              .word 0x00000128
onetwonine:               .word 0x00000129
onethree:                   .word 0x00000130
onethreeone:                .word 0x00000131
onethreetwo:                .word 0x00000132
onethreethree:              .word 0x00000133
onethreefour:               .word 0x00000134
onethreefive:               .word 0x00000135
onethreesix:                .word 0x00000136
onethreeseven:              .word 0x00000137
onethreeeight:              .word 0x00000138
onethreenine:               .word 0x00000139
onefour:                   .word 0x00000140
onefourone:                .word 0x00000141
onefourtwo:                .word 0x00000142
onefourthree:              .word 0x00000143
onefourfour:               .word 0x00000144
onefourfive:               .word 0x00000145
onefoursix:                .word 0x00000146
onefourseven:              .word 0x00000147
onefoureight:              .word 0x00000148
onefournine:               .word 0x00000149
onefive:                   .word 0x00000150
onefiveone:                .word 0x00000151
onefivetwo:                .word 0x00000152
onefivethree:              .word 0x00000153
onefivefour:               .word 0x00000154
onefivefive:               .word 0x00000155
onefivesix:                .word 0x00000156
onefiveseven:              .word 0x00000157
onefiveeight:              .word 0x00000158
onefivenine:               .word 0x00000159
onesix:                   .word 0x0000160
onesixone:                .word 0x0000161
onesixtwo:                .word 0x0000162
onesixthree:              .word 0x0000163
onesixfour:               .word 0x0000164
onesixfive:               .word 0x0000165
onesixsix:                .word 0x0000166
onesixseven:              .word 0x0000167
onesixeight:              .word 0x0000168
onesixnine:               .word 0x0000169
oneseven:                   .word 0x00000170
onesevenone:                .word 0x00000171
oneseventwo:                .word 0x00000172
oneseventhree:              .word 0x00000173
onesevenfour:               .word 0x00000174
onesevenfive:               .word 0x00000175
onesevensix:                .word 0x00000176
onesevenseven:              .word 0x00000177
oneseveneight:              .word 0x00000178
onesevennine:               .word 0x00000179
oneeight:                   .word 0x00000180
oneeightone:                .word 0x00000181
oneeighttwo:                .word 0x00000182
oneeightthree:              .word 0x00000183
oneeightfour:               .word 0x00000184
oneeightfive:               .word 0x00000185
oneeightsix:                .word 0x00000186
oneeightseven:              .word 0x00000187
oneeighteight:              .word 0x00000188
oneeightnine:               .word 0x00000189
onenine:                   .word 0x00000190
onenineone:                .word 0x00000191
oneninetwo:                .word 0x00000192
oneninethree:              .word 0x00000193
oneninefour:               .word 0x00000194
oneninefive:               .word 0x00000195
oneninesix:                .word 0x00000196
onenineseven:              .word 0x00000197
onenineeight:              .word 0x00000198
oneninenine:               .word 0x00000199
twoo:                   .word 0x00000210
twooone:                .word 0x00000211
twootwo:                .word 0x00000212
twoothree:              .word 0x00000213
twoofour:               .word 0x00000214
twoofive:               .word 0x00000215
twoosix:                .word 0x00000216
twooseven:              .word 0x00000217
twooeight:              .word 0x00000218
twoonine:               .word 0x00000219
twoone:                   .word 0x00000210
twooneone:                .word 0x00000211
twoonetwo:                .word 0x00000212
twoonethree:              .word 0x00000213
twoonefour:               .word 0x00000214
twoonefive:               .word 0x00000215
twoonesix:                .word 0x00000216
twooneseven:              .word 0x00000217
twooneeight:              .word 0x00000218
twoonenine:               .word 0x00000219
twotwo:                   .word 0x00000220
twotwoone:                .word 0x00000221
twotwotwo:                .word 0x00000222
twotwothree:              .word 0x00000223
twotwofour:               .word 0x00000224
twotwofive:               .word 0x00000225
twotwosix:                .word 0x00000226
twotwoseven:              .word 0x00000227
twotwoeight:              .word 0x00000228
twotwonine:               .word 0x00000229
twothree:                   .word 0x00000230
twothreeone:                .word 0x00000231
twothreetwo:                .word 0x00000232
twothreethree:              .word 0x00000233
twothreefour:               .word 0x00000234
twothreefive:               .word 0x00000235
twothreesix:                .word 0x00000236
twothreeseven:              .word 0x00000237
twothreeeight:              .word 0x00000238
twothreenine:               .word 0x00000239
twofour:                   .word 0x00000240
twofourone:                .word 0x00000241
twofourtwo:                .word 0x00000242
twofourthree:              .word 0x00000243
twofourfour:               .word 0x00000244
twofourfive:               .word 0x00000245
twofoursix:                .word 0x00000246
twofourseven:              .word 0x00000247
twofoureight:              .word 0x00000248
twofournine:               .word 0x00000249
twofive:                   .word 0x00000250
twofiveone:                .word 0x00000251
twofivetwo:                .word 0x00000252
twofivethree:              .word 0x00000253
twofivefour:               .word 0x00000254
twofivefive:               .word 0x00000255
twofivesix:                .word 0x00000256
twofiveseven:              .word 0x00000257
twofiveeight:              .word 0x00000258
