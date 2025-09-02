pragma Singleton

import QtQuick

Item {
    property string currentImagePath: ""
    property real imageWidth: 0
    property real imageHeight: 0
    property int imageFileSize: 0

    function loadImage(imagePath) {
        currentImagePath = imagePath
        imageFileSize = ImageLoader.getFileSize(imagePath)
    }

    function getFileName(filePath) {
        if (filePath === "") return ""

        var path = filePath.toString()
        if (path.startsWith("file://")) {
            path = path.substring(7)
        }

        var lastSlash = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'))
        return lastSlash >= 0 ? path.substring(lastSlash + 1) : path
    }

    function formatFileSize(bytes) {
        if (bytes === 0) return "0 B"

        var k = 1024
        var sizes = ["B", "KB", "MB", "GB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))

        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
    }
}
