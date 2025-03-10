#!/bin/bash

# 将所有参数传递给 Build.hx
# haxe --run Build.hx [----update-libs]
# haxe --run Build.hx
haxe --run Build.hx "$@"
