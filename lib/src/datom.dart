toEavt(e) {
  if (e is List) {
    return e.map((e) => toEavt(e)).toList();
  } else if(e is Map) {
    return [e['e'], e['a'], e['v'], e['tx']];
  }
}
