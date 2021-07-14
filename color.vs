struct vs_in {
  float4 pos: POSITION;
  float4 color: COLOR;
};

struct vs_out {
  float4 pos: SV_Position;
  float4 color: COLOR;
};

vs_out main(vs_in input) {
  vs_out outp;
  outp.pos = input.pos;
  outp.color = input.color;
  return outp;
}