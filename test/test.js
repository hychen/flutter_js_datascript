var vendor = 1;

function fnInJsFile() {
  return 42 + vendor;
}

function push_pack(k, v) {
  'state.${k} = ${jsonEncode(v)}'
}

