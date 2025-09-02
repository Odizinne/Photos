import QtQuick
import QtQuick.Controls.Universal
import QtQuick.Controls.impl
import QtQuick.Layouts
import QtQuick.Dialogs
import Odizinne.Photos

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    minimumWidth: 1000
    minimumHeight: 700
    title: "Photos"
    Universal.theme: Universal.System
    Universal.accent: palette.highlight

    Shortcut {
        sequence: "Esc"
        enabled: window.visibility === Window.FullScreen
        onActivated: window.toggleFullscreen()
    }

    Shortcut {
        sequence: "F11"
        onActivated: window.toggleFullscreen()
    }

    Shortcut {
        sequence: StandardKey.Open
        onActivated: fileDialog.open()
    }

    Shortcut {
        sequences: [StandardKey.Copy]
        enabled: Common.currentImagePath !== ""
        onActivated: ImageLoader.copyImageToClipboard(Common.currentImagePath)
    }

    Shortcut {
        sequences: [StandardKey.Paste]
        onActivated: window.pasteImageFromClipboard()
    }

    onClosing: function(close) {
        if (ImageLoader.hasPendingOperations()) {
            close.accepted = false // Don't close yet
            saveDialog.open()
        }
    }

    Component.onCompleted: {
        var initialPath = ImageLoader.getInitialImagePath()
        if (initialPath !== "") {
            Common.loadImage(initialPath)
        }
    }

    Connections {
        target: ImageLoader

        function onImageRotationComplete(filePath, success) {
            if (success && filePath === Common.currentImagePath) {
                Common.imageFileSize = ImageLoader.getFileSize(Common.currentImagePath)
            } else if (!success) {
                console.log("Failed to rotate image")
            }
        }

        function onAllOperationsComplete() {
            if (saveDialog.opened) {
                saveDialog.close()
                Qt.quit()
            }
        }
    }

    Dialog {
        id: saveDialog
        title: "Saving changes"
        modal: true
        anchors.centerIn: parent
        closePolicy: Popup.NoAutoClose

        Column {
            spacing: 20

            Label {
                text: "Please wait while changes are being saved..."
                anchors.horizontalCenter: parent.horizontalCenter
            }

            BusyIndicator {
                running: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Dialog {
        id: deleteConfirmDialog
        title: "Delete Image"
        modal: true
        anchors.centerIn: parent

        Column {
            spacing: 20
            width: 300

            Label {
                text: "Are you sure you want to delete this image?"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Label {
                text: Common.currentImagePath !== "" ? Common.getFileName(Common.currentImagePath) : ""
                font.bold: true
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Label {
                text: "This will move the file to the recycle bin."
                font.pointSize: 9
                opacity: 0.7
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }

            Button {
                text: "Delete"
                highlighted: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }

        onAccepted: window.deleteCurrentImage()
        onRejected: close()
    }

    header: ToolBar {
        height: 40
        background: Rectangle {
            implicitHeight: 48
            color: Universal.background
        }

        Button {
            id: openButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            highlighted: true
            height: 40
            text: "Open image"
            onClicked: fileDialog.open()
        }

        Row {
            anchors.centerIn: parent
            spacing: 0

            ToolButton {
                icon.source: "qrc:/icons/delete.svg"
                width: 40
                height: 40
                enabled: Common.currentImagePath !== ""
                flat: true
                onClicked: deleteConfirmDialog.open()
            }
            ToolButton {
                icon.source: "qrc:/icons/rotate_left.svg"
                width: 40
                height: 40
                enabled: Common.currentImagePath !== ""
                flat: true
                onClicked: window.rotateImage(-90)
            }
            ToolButton {
                icon.source: "qrc:/icons/rotate_right.svg"
                width: 40
                height: 40
                enabled: Common.currentImagePath !== ""
                flat: true
                onClicked: window.rotateImage(90)
            }
        }

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            text: Common.currentImagePath !== "" ? Common.getFileName(Common.currentImagePath) : ""
            width: Math.min(300, implicitWidth)
            elide: Text.ElideMiddle
            opacity: 0.5
        }
    }

    Flickable {
        id: imageFlickable
        anchors.fill: parent

        // Fix: Calculate content dimensions based on rotation
        contentWidth: {
            if (!displayImage.implicitWidth || !displayImage.implicitHeight) return width

            var imgW = displayImage.implicitWidth * imageContainer.scale
            var imgH = displayImage.implicitHeight * imageContainer.scale

            // When rotated 90° or 270°, width becomes height
            if (Math.abs(imageRotation) % 180 !== 0) {
                return Math.max(imgH, width)
            }
            return Math.max(imgW, width)
        }

        contentHeight: {
            if (!displayImage.implicitWidth || !displayImage.implicitHeight) return height

            var imgW = displayImage.implicitWidth * imageContainer.scale
            var imgH = displayImage.implicitHeight * imageContainer.scale

            // When rotated 90° or 270°, height becomes width
            if (Math.abs(imageRotation) % 180 !== 0) {
                return Math.max(imgW, height)
            }
            return Math.max(imgH, height)
        }

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        property real minScale: 0.1
        property real maxScale: 8.0
        property real imageRotation: 0

        onWidthChanged: updateMinScale()
        onHeightChanged: updateMinScale()
        ContextMenu.menu: Menu {
            enter: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 150
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1.0
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            exit: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 100
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    property: "scale"
                    from: 1.0
                    to: 0.95
                    duration: 100
                    easing.type: Easing.InQuad
                }
            }
            opacity: Common.currentImagePath !== "" ? 1 : 0
            MenuItem {
                text: "Copy image"
                enabled: Common.currentImagePath !== ""
                onTriggered: ImageLoader.copyImageToClipboard(Common.currentImagePath)
            }

            MenuItem {
                text: "Copy image path"
                enabled: Common.currentImagePath !== ""
                onTriggered: ImageLoader.copyPathToClipboard(Common.currentImagePath)
            }

            MenuItem {
                text: "Set as desktop wallpaper"
                enabled: Common.currentImagePath !== ""
                onTriggered: ImageLoader.setDesktopWallpaperAsync(Common.currentImagePath)
            }

            MenuItem {
                text: "Set as lockscreen wallpaper"
                enabled: Common.currentImagePath !== ""
                onTriggered: ImageLoader.setLockScreenWallpaperAsync(Common.currentImagePath)
            }

            MenuItem {
                text: "Set both wallpapers"
                enabled: Common.currentImagePath !== ""
                onTriggered: ImageLoader.setBothWallpapersAsync(Common.currentImagePath)
            }

            MenuSeparator {}

            MenuItem {
                text: "Fit to window"
                enabled: Common.currentImagePath !== ""
                onTriggered: imageFlickable.fitToWindow()
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onDoubleTapped: window.toggleFullscreen()
            enabled: Common.currentImagePath !== ""
        }

        DropArea {
                id: dropArea
                anchors.fill: parent

                onEntered: function(drag) {
                    // Check if the dragged item contains files
                    if (drag.hasUrls) {
                        var supportedFormats = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp"]
                        var hasImageFile = false

                        for (var i = 0; i < drag.urls.length; i++) {
                            var url = drag.urls[i].toString().toLowerCase()
                            for (var j = 0; j < supportedFormats.length; j++) {
                                if (url.endsWith(supportedFormats[j])) {
                                    hasImageFile = true
                                    break
                                }
                            }
                            if (hasImageFile) break
                        }

                        if (hasImageFile) {
                            drag.accept(Qt.CopyAction)
                        } else {
                            drag.accepted = false
                        }
                    }
                }

                onDropped: function(drop) {
                    if (drop.hasUrls && drop.urls.length > 0) {
                        var supportedFormats = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp"]

                        // Find the first supported image file
                        for (var i = 0; i < drop.urls.length; i++) {
                            var url = drop.urls[i].toString().toLowerCase()
                            for (var j = 0; j < supportedFormats.length; j++) {
                                if (url.endsWith(supportedFormats[j])) {
                                    // Load the first supported image file found
                                    Common.loadImage(drop.urls[i])
                                    drop.accept(Qt.CopyAction)
                                    return
                                }
                            }
                        }
                    }
                    drop.accepted = false
                }
            }

        function updateMinScale() {
            if (displayImage.implicitWidth > 0 && displayImage.implicitHeight > 0) {
                var imgWidth = displayImage.implicitWidth
                var imgHeight = displayImage.implicitHeight

                // For min scale calculation, use rotated dimensions
                if (Math.abs(imageRotation) % 180 !== 0) {
                    var temp = imgWidth
                    imgWidth = imgHeight
                    imgHeight = temp
                }

                var scaleX = width / imgWidth
                var scaleY = height / imgHeight
                var fitScale = Math.min(scaleX, scaleY)
                var newMinScale = Math.max(fitScale, 0.1)

                var oldMinScale = minScale
                var wasAtMinimum = imageContainer.scale <= (oldMinScale * 1.05)

                minScale = newMinScale

                if (wasAtMinimum || imageContainer.scale < newMinScale) {
                    imageContainer.scale = newMinScale
                }

                if (zoomSlider) {
                    zoomSlider.from = newMinScale
                    zoomSlider.value = imageContainer.scale
                }
            }
        }

        Item {
            id: imageContainer
            anchors.centerIn: parent
            scale: 1.0
            // Keep original dimensions - rotation is visual only
            width: displayImage.implicitWidth
            height: displayImage.implicitHeight

            Behavior on scale {
                enabled: Common.enableScaleAnimation
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Image {
                id: displayImage
                anchors.centerIn: parent
                source: Common.currentImagePath
                fillMode: Image.PreserveAspectFit
                rotation: imageFlickable.imageRotation

                onStatusChanged: {
                    if (status === Image.Ready) {
                        // Disable animations before any scale changes
                        window.Common.enableScaleAnimation = false

                        Common.imageWidth = implicitWidth
                        Common.imageHeight = implicitHeight

                        imageFlickable.imageRotation = 0

                        // Ensure proper initialization sequence
                        Qt.callLater(function() {
                            imageFlickable.updateMinScale()
                            imageFlickable.fitToWindow()
                            // Re-enable scale animations after initial setup
                            window.Common.enableScaleAnimation = true
                        })

                        window.title = Common.getFileName(Common.currentImagePath) + " - Image Viewer"
                    } else if (status === Image.Error) {
                        console.log("Error loading image:", Common.currentImagePath)
                        window.title = "Image Viewer - Error loading image"
                        imageFlickable.minScale = 0.1
                        imageFlickable.imageRotation = 0
                    }
                }
            }
        }

        Label {
            anchors.centerIn: parent
            text: "Load an image to get started"
            opacity: 0.7
            visible: Common.currentImagePath === ""
            font.pointSize: 16
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: function(event) {
                var scaleFactor = event.angleDelta.y > 0 ? 1.2 : 0.8
                var newScale = imageContainer.scale * scaleFactor

                if (newScale >= imageFlickable.minScale && newScale <= imageFlickable.maxScale) {
                    imageContainer.scale = newScale
                    // Update slider to match
                    zoomSlider.value = newScale
                }
            }
        }

        function fitToWindow() {
            if (displayImage.implicitWidth === 0 || displayImage.implicitHeight === 0)
                return

            var imgWidth = displayImage.implicitWidth
            var imgHeight = displayImage.implicitHeight

            // Consider rotation for fit calculation
            if (Math.abs(imageRotation) % 180 !== 0) {
                var temp = imgWidth
                imgWidth = imgHeight
                imgHeight = temp
            }

            var scaleX = width / imgWidth
            var scaleY = height / imgHeight
            var newScale = Math.min(scaleX, scaleY, 1.0)

            imageContainer.scale = newScale
            if (zoomSlider) {
                zoomSlider.value = newScale
            }
        }
    }

    footer: ToolBar {
        visible: Common.currentImagePath !== ""
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10

            IconLabel {
                icon.source: "qrc:/icons/res.svg"
                icon.width: 16
                icon.height: 16
                icon.color: Universal.foreground
                color: Universal.foreground
                spacing: 6
                opacity: 0.5
                text: Common.currentImagePath !== "" ?
                      "Resolution: " + Math.round(Common.imageWidth) + " × " + Math.round(Common.imageHeight) :
                      "No image loaded"
            }

            ToolSeparator {
                opacity: 0.5
            }

            IconLabel {
                icon.source: "qrc:/icons/disk.svg"
                icon.width: 13
                icon.height: 13
                icon.color: Universal.foreground
                color: Universal.foreground
                spacing: 6
                opacity: 0.5
                text: Common.currentImagePath !== "" ?
                      "Size: " + Common.formatFileSize(Common.imageFileSize) :
                      ""
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                icon.source: "qrc:/icons/fit.svg"
                Layout.preferredWidth: height
                onClicked: imageFlickable.fitToWindow()
                enabled: Common.currentImagePath !== ""
                ToolTip.visible: hovered
                ToolTip.text: "Fit to window"
            }

            ToolButton {
                icon.source: "qrc:/icons/zoom_out.svg"
                Layout.preferredWidth: height
                onClicked: {
                    var newScale = imageContainer.scale * 0.9
                    if (newScale >= imageFlickable.minScale) {
                        imageContainer.scale = newScale
                        zoomSlider.value = newScale
                    }
                }
                enabled: Common.currentImagePath !== "" && imageContainer.scale > imageFlickable.minScale
                ToolTip.visible: hovered
                ToolTip.text: "Zoom out"
            }

            Slider {
                id: zoomSlider
                Layout.preferredWidth: 150
                visible: Common.currentImagePath !== ""

                from: imageFlickable.minScale
                to: imageFlickable.maxScale
                value: imageContainer.scale

                onValueChanged: {
                    if (Math.abs(value - imageContainer.scale) > 0.01) {
                        imageContainer.scale = value
                    }
                }
            }

            ToolButton {
                icon.source: "qrc:/icons/zoom_in.svg"
                Layout.preferredWidth: height
                onClicked: {
                    var newScale = imageContainer.scale * 1.1
                    if (newScale <= imageFlickable.maxScale) {
                        imageContainer.scale = newScale
                        zoomSlider.value = newScale
                    }
                }
                enabled: Common.currentImagePath !== "" && imageContainer.scale < imageFlickable.maxScale
                ToolTip.visible: hovered
                ToolTip.text: "Zoom in"
            }

            Label {
                id: percentageZoomLabel
                text: Common.currentImagePath !== "" ?
                      Math.round(imageContainer.scale * 100) + "%" :
                      ""
                Layout.preferredWidth: fontMetrics.advanceWidth("888%")
                horizontalAlignment: Text.AlignHCenter
                FontMetrics {
                    id: fontMetrics
                    font: percentageZoomLabel.font
                }
            }


            ToolButton {
                icon.source: "qrc:/icons/fullscreen.svg"
                Layout.preferredWidth: height
                onClicked: window.toggleFullscreen()
                enabled: Common.currentImagePath !== ""
                ToolTip.visible: hovered
                ToolTip.text: window.visibility === Window.FullScreen ? "Exit fullscreen" : "Enter fullscreen"
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Open Image"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "Image files (*.jpg *.jpeg *.png *.gif *.bmp *.tiff *.tif *.webp)",
            "JPEG files (*.jpg *.jpeg)",
            "PNG files (*.png)",
            "All files (*)"
        ]

        onAccepted: {
            Common.loadImage(selectedFile)
        }
    }

    function toggleFullscreen() {
        if (window.visibility === Window.FullScreen) {
            window.showNormal()
            header.visible = true
            footer.visible = true
        } else {
            window.showFullScreen()
            header.visible = false
            footer.visible = false
        }
    }

    function deleteCurrentImage() {
        if (Common.currentImagePath !== "") {
            var success = ImageLoader.deleteImage(Common.currentImagePath)

            if (success) {
                // Disable animations before clearing
                Common.enableScaleAnimation = false

                Common.currentImagePath = ""
                Common.imageFileSize = 0
                Common.imageWidth = 0
                Common.imageHeight = 0
                window.title = "Image Viewer"

                imageFlickable.imageRotation = 0
                imageFlickable.minScale = 0.1
                imageContainer.scale = 1.0

                console.log("Image deleted successfully")
            } else {
                console.log("Failed to delete image")
            }
        }
    }

    function rotateImage(angle) {
        if (Common.currentImagePath !== "") {
            Common.enableScaleAnimation = false

            imageFlickable.imageRotation = (imageFlickable.imageRotation + angle + 360) % 360
            imageFlickable.fitToWindow()

            Qt.callLater(function() {
                Common.enableScaleAnimation = true
            })

            ImageLoader.rotateAndSaveImageAsync(Common.currentImagePath, angle)
        }
    }

    function pasteImageFromClipboard() {
        var imagePath = ImageLoader.pasteImageFromClipboard()
        if (imagePath !== "") {
            Common.loadImage(imagePath)
        }
    }
}
