var fs = require('fs'), path = require('path');

module.exports = function(context) {

    var platformRoot = path.join(context.opts.projectRoot, 'platforms/ios');
    var podFile = path.join(platformRoot, 'Podfile');
    
    if (fs.existsSync(podFile)) {
     
      fs.readFile(podFile, 'utf8', function (err,data) {
        
        if (err) {
          throw new Error('Unable to find Podfile: ' + err);
        }

          if (!data.includes("use_frameworks!")){
            data = data.replace(/ do/g, ' do\nuse_frameworks!');
          } 

          if (!data.includes("TensorIO")){
              data = data.replace(/end/g, 'pod \'TensorIO/TFLite\'\nend');
            } 

          var result = data.replace(/8.0/g, '9.3');

          fs.writeFile(podFile, result, 'utf8', function (err) {
            if (err) throw new Error('Unable to write into Podfile ' + err);
          });
      });
    } else {

        //NEEDS TO BE FINISHED

        /*console.log("Podfile does not exist. Creating it.");
        var podfileData = 'platform :ios, \'9.3\'\n' +
                          'use_frameworks!\n' +
                          'target \'%s\' do\n' +
                          '\tproject \'%s.xcodeproj\'\n' +
                          '%s\n' +
                          'end\n';
        fs.writeFile(podFile, podfileData, 'utf8', function (err) {
            if (err) throw new Error('Unable to write into the new Podfile: ' + err);
          });

        var podFileJS = path.join(context.opts.projectRoot, 'platforms/ios/cordova/lib/Podfile.js');

        fs.readFile(podFileJS, 'utf8', function (err,data) {
          data = data.replace(/8.0/g, '9.3');
          data = data.replace(/target/g, '\\nuse_frameworks!\\ntarget');

          console.log("ALTERANDO O PODFILE.JS!");
          fs.writeFile(podFileJS, data, 'utf8', function (err) {
            if (err) throw new Error('Unable to write into Podfile.js: ' + err);
          });
        })
        */
    }
  }
