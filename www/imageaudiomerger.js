/*global cordova, module*/

module.exports = {
    merge: function (imagePath, audioPath, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "imageaudiomerger", "merge", [imagePath, audioPath]);
    }
};
