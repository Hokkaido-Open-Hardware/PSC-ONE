# TJpgDec dependency

`third_party/tjpgd` is a Git submodule of
[Bodmer/TJpg_Decoder](https://github.com/Bodmer/TJpg_Decoder), pinned to
`71bfc2607b6963ee3334ff6f601345c5d2b7a8da` (tag `V1.1.0`, 2023-11-08).
This is a maintained distribution of ChaN's TJpgDec, **not ChaN's official Git
repository**. The original distribution is at <https://elm-chan.org/fsw/tjpgd/>.

The release contains TJpgDec R0.03 and the official grayscale overflow patch
(commit `c115a505b5e949d4604252d9175ff36bab44af5c`). We chose this tagged release
rather than following a moving branch. Only `src/tjpgd.c` and `src/tjpgd.h` are
compiled; the Arduino C++ wrappers and filesystem/display integrations are not.
The submodule must remain clean. The parent gitlink, not a branch setting,
records the exact commit.

From the parent repository:

```sh
git submodule update --init --recursive
```

For a new checkout, `git clone --recurse-submodules <PSC-ONE-repository-URL>`
initializes the dependencies. If updating an existing initialized checkout,
run the update command again after pulling. No source download is performed
implicitly by the OS Makefile.

The decoder includes `"tjpgdcnf.h"` beside its header. Merely putting a PSC
configuration earlier in `-I` would still select upstream's RGB565 settings.
The Makefile therefore creates **relative symlinks in the ignored build
folder** to upstream `tjpgd.c`/`.h` and PSC's `src/jpeg/tjpgdcnf.h`. The source
bytes remain in the submodule; no vendor copy or patch is stored in PSC source.
All adapters include the same build-folder header, keeping the JDEC ABI equal.

## License notices

TJpgDec's source headers retain Copyright (C) 2021 ChaN and its permissive
BSD-style license: no restriction on use, modification or redistribution;
redistributed source must retain the copyright notice; no warranty.
See [upstream source](tjpgd/src/tjpgd.c) and [license.txt](tjpgd/license.txt).
The latter also covers Bodmer's additions. Preserve these notices when
redistributing sources and include this document with binary distributions.

Software License Agreement (FreeBSD License)

Copyright (c) 2019 Bodmer (https://github.com/Bodmer)

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
