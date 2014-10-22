/*
 * Copyright 2014 Domabo; Portions Copyright 2014 Tim Schaub
 *
 * Licensed under the the MIT license (the "License");
 * you may not use this file except in compliance with the License.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the “Software”), to deal 
 * in the Software without restriction, including without limitation the rights 
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in 
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
 * OTHER DEALINGS IN THE SOFTWARE.
 */

var Directory = require('./directory');
var File = require('./file');
var FSError = require('./error');
var SymbolicLink = require('./symlink');
var Promise = require('promise');

/**
 * Create a new file system for OSX bridge
 * @constructor
 */
function FileSystem() {
}

/**
 * Get a file system item.
 * @param {string} filepath Path to item.
 * @return {Promise<Item>} The item (or null if not found).
 */
FileSystem.prototype.getItemAsync = function (filepath) {
    console.log('fs ' + filepath);
    
    var fs_StatAsync = Promise.denodeify(function(id, callback){io.nodekit.fs.statAsync(id, callback);});
    
    io.nodekit.console.log("Getting " + filepath);
    
    return fs_StatAsync(filepath)
    .then(function(storageItem){
         return FileSystem.storageItemtoItemWithStat(storageItem);
          });
}

/**
 * Get a file system item.
 * @param {string} filepath Path to item.
 * @return {Promise<Item>} The item (or null if not found).
 */
FileSystem.prototype.getItemSync = function (filepath) {
    var storageItem = io.nodekit.fs.stat(filepath);
    return FileSystem.storageItemtoItemWithStat(storageItem);
};

/**
 * Get a file system item.
 * @param {string} filepath Path to item.
 * @return {Promise<Item>} The item (or null if not found).
 */
FileSystem.storageItemtoItemWithStat = function (storageItem) {
    
    var stat = {};
    
    if (storageItem) {
        stat.path = storageItem.path;
        stat.birthtime = storageItem.birthtime;
        stat.mtime = storageItem.DateModified;
        stat.atime = stat.mtime;
        stat.ctime = stat.mtime;
        stat.uid = 0;
        stat.gid = 0;
        stat.dev = 0;
        stat.ino = 0;
        stat.nlink =1;
        
        if (storageItem.filetype == "Directory")
        {
            stat.mode = 438; // 0777;
            stat._isFolder = true;
            stat._isFile = false;
            stat.size = 0;
            var dir = new FileSystem.directory(stat)();
            dir._storageItem = storageItem;
            return dir;
            
        }
        else
        {
            stat.mode = 0666;
            stat._isFolder = false;
            stat._isFile = true;
            stat.size = storageItem.size;
            var file = new FileSystem.file(stat)();
            file._storageItem = storageItem;
            return file;
        };
    }
    else
    {
        throw new FSError('ENOENT');
    }
    

};


/**
 * Load Content
 * @param {file} file
 * @return {Promise<Item>} The item (or null if not found).
 */
FileSystem.prototype.loadContentSync = function (file) {
    var content = io.nodekit.fs.getContent(file._storageItem);
    file.setContent(content);
    return file;
};

/**
 * Load Content
 * @param {file} file
 * @return {Promise<Item>} The item (or null if not found).
 */
FileSystem.prototype.loadContentAsync = function (file) {
    io.nodekit.console.log("loadContentAsync ");
    
    var fs_getContent = Promise.denodeify(function(id, callback){io.nodekit.fs.getContentAsync(id, callback);});
    
    return fs_getContent(file._storageItem)
    .then(function(content){
          file.setContent(content);
          return file;
          });
};

/**
 * Get directory listing
 * @param {string} filepath Path to directory.
 * @return {Promise<[]>} The array of item names (or error if not found or not a directory).
 */
FileSystem.prototype.getDirList = function (filepath) {
    
    var fs_getDirectory = Promise.denodeify(function(id, callback){io.nodekit.fs.getDirectory(id, callback);});
    
    return fs_getDirectory(filepath);
};

/**
 * Generate a factory for new files.
 * @param {Object} config File config.
 * @return {function():File} Factory that creates a new file.
 */
FileSystem.file = function (config) {
  config = config || {};
  return function() {
    var file = new File();
    if (config.hasOwnProperty('content')) {
      file.setContent(config.content);
    }
    if (config.hasOwnProperty('mode')) {
      file.setMode(config.mode);
    } else {
      file.setMode(0666);
    }
      if (config.hasOwnProperty('path')) {
          file.setPath(config.path);
      } else {
          throw new Error('Missing "path" property');
      }
      
    if (config.hasOwnProperty('uid')) {
      file.setUid(config.uid);
    }
    if (config.hasOwnProperty('gid')) {
      file.setGid(config.gid);
    }
      if (config.hasOwnProperty('size')) {
          file.setSize(config.size);
      }
    if (config.hasOwnProperty('atime')) {
      file.setATime(config.atime);
    }
    if (config.hasOwnProperty('ctime')) {
      file.setCTime(config.ctime);
    }
    if (config.hasOwnProperty('mtime')) {
      file.setMTime(config.mtime);
    }
    return file;
  };
};


/**
 * Generate a factory for new symbolic links.
 * @param {Object} config File config.
 * @return {function():File} Factory that creates a new symbolic link.
 */
FileSystem.symlink = function (config) {
  config = config || {};
  return function() {
    var link = new SymbolicLink();
    if (config.hasOwnProperty('mode')) {
      link.setMode(config.mode);
    } else {
      link.setMode(0666);
    }
    if (config.hasOwnProperty('uid')) {
      link.setUid(config.uid);
    }
    if (config.hasOwnProperty('gid')) {
      link.setGid(config.gid);
    }
    if (config.hasOwnProperty('path')) {
      link.setPath(config.path);
    } else {
      throw new Error('Missing "path" property');
    }
    if (config.hasOwnProperty('atime')) {
      link.setATime(config.atime);
    }
    if (config.hasOwnProperty('size')) {
          link.setSize(config.size);
      }
    if (config.hasOwnProperty('ctime')) {
      link.setCTime(config.ctime);
    }
    if (config.hasOwnProperty('mtime')) {
      link.setMTime(config.mtime);
    }
    return link;
  };
};


/**
 * Generate a factory for new directories.
 * @param {Object} config File config.
 * @return {function():Directory} Factory that creates a new directory.
 */
FileSystem.directory = function (config) {
  config = config || {};
  return function() {
    var dir = new Directory();
    if (config.hasOwnProperty('mode')) {
      dir.setMode(config.mode);
    }
    if (config.hasOwnProperty('uid')) {
      dir.setUid(config.uid);
    }
    if (config.hasOwnProperty('gid')) {
      dir.setGid(config.gid);
    }
    if (config.hasOwnProperty('atime')) {
      dir.setATime(config.atime);
    }
    if (config.hasOwnProperty('ctime')) {
      dir.setCTime(config.ctime);
    }
    if (config.hasOwnProperty('mtime')) {
      dir.setMTime(config.mtime);
    }
    return dir;
  };
};


/**
 * Module exports.
 * @type {function}
 */
module.exports = FileSystem;


