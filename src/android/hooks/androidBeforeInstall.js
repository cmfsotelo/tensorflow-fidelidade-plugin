#!/usr/bin/env node

var fs = require('fs'), path = require('path');

module.exports = function(context) {
    console.log("========== Executing hook androidBeforeInstall.js  ==========");
    var platformRoot = path.join(context.opts.projectRoot, 'platforms/android');
    var manifestFile = path.join(platformRoot, 'app/src/main/AndroidManifest.xml');
  
    if (fs.existsSync(manifestFile)) {
  
      fs.readFile(manifestFile, 'utf8', function (err,data) {
        if (err) {
          throw new Error('Unable to find AndroidManifest.xml: ' + err);
        }
  
          var tagValue = 'android:icon';
          var merge = 'merge';
          var result = data.replace(/<application/g, '<application tools:replace="' + tagValue + '" tools:node="'+merge+'"');
          
          console.log("========== Updating the AndroidManifest.xml on Android ==========");
  
          fs.writeFile(manifestFile, result, 'utf8', function (err) {
            if (err) throw new Error('Unable to write into AndroidManifest.xml: ' + err);
          });

          var schema = 'http://schemas.android.com/tools';
          var addToolsSchema = result.replace(/<manifest/g, '<manifest xmlns:tools="'+schema+'"');

          fs.writeFile(manifestFile, addToolsSchema, 'utf8', function (err) {        
            if (err) throw new Error('Unable to write into AndroidManifest.xml: ' + err);
    
          });

          // Addind a merge tag

        
      });
    }
  };