/*
 * nodekit.io
 *
 * Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
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

this.process = this.process || {}

var process = this.process;

process.platform = process.platform || "darwin"

process.type = "main"

process.versions = {}

process.waitFor = function(signal) {

    window.prompt("nk.Signal", signal);

}

process.bootstrap.NativeModule.loadPreCacheSource('electro',  process.bootstrap.NativeModule.getSource('lib-electro.nkar/lib-electro/electro.js'))