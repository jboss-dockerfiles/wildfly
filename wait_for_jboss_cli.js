#!/usr/bin/jjs

function canConnect() {
  try {
    new java.net.Socket("localhost", 9990)
    return true
  } catch(e) {
    return false
  }
}

while(!canConnect()) { }
