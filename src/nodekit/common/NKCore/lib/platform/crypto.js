/*
 * nodekit.io
 *
 * Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
 * Portions Copyright (c) 2013 GitHub, Inc. under MIT License
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
this.global = this;

if (!global.crypto) {
    global.crypto = {}
}


if (!global.crypto.randomBytes) {
    global.crypto.randomBytes = function (size) {
        return new Buffer(io.nodekit.crypto.getRandomBytesSync(size));
    };
}

if (!global.crypto.getRandomValues) {
    
    // copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
    global.crypto.getRandomValues = function (bytes) {
        var buf = new Buffer(io.nodekit.crypto.getRandomBytesSync(bytes.length))
        buf.copy(bytes);
    };
}