#include "ImageLoader.h"

ImageLoader* ImageLoader::s_instance = nullptr;

ImageLoader::ImageLoader(QObject *parent) : QObject(parent)
{
    // Process command line arguments
    QStringList args = QGuiApplication::arguments();

    if (args.size() > 1) {
        QString filePath = args.at(1);
        QFileInfo fileInfo(filePath);

        if (fileInfo.exists() && fileInfo.isFile()) {
            m_initialImagePath = QUrl::fromLocalFile(fileInfo.absoluteFilePath()).toString();
        }
    }
}

ImageLoader* ImageLoader::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    if (!s_instance) {
        s_instance = new ImageLoader();
    }
    return s_instance;
}

ImageLoader* ImageLoader::instance()
{
    return s_instance;
}

QString ImageLoader::getInitialImagePath() const
{
    return m_initialImagePath;
}

qint64 ImageLoader::getFileSize(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    return fileInfo.size();
}

void ImageLoader::rotateAndSaveImageAsync(const QString &filePath, int angle)
{
    {
        QMutexLocker locker(&m_operationsMutex);

        // Accumulate the rotation instead of starting multiple operations
        m_pendingRotations[filePath] += angle;

        // If there's already an operation for this file, just return
        // The accumulated rotation will be applied when the current operation completes
        if (m_pendingRotations[filePath] != angle) {
            return;
        }

        m_pendingOperations++;
    }

    // Run rotation in background thread
    QFuture<bool> future = QtConcurrent::run([this, filePath]() {
        int totalAngle;
        {
            QMutexLocker locker(&m_operationsMutex);
            totalAngle = m_pendingRotations[filePath];
        }
        return performRotation(filePath, totalAngle);
    });

    // Watch for completion
    QFutureWatcher<bool> *watcher = new QFutureWatcher<bool>(this);

    connect(watcher, &QFutureWatcher<bool>::finished, [this, watcher, filePath]() {
        bool success = watcher->result();

        int appliedRotation;
        {
            QMutexLocker locker(&m_operationsMutex);
            appliedRotation = m_pendingRotations[filePath];
            m_pendingRotations.remove(filePath);
            m_pendingOperations--;

            if (m_pendingOperations == 0) {
                emit allOperationsComplete();
            }
        }

        emit imageRotationComplete(filePath, success);
        watcher->deleteLater();

        // If there were additional rotations requested while processing, handle them
        {
            QMutexLocker locker(&m_operationsMutex);
            if (success && m_pendingRotations.contains(filePath)) {
                // There are more rotations pending for this file
                QMetaObject::invokeMethod(this, "rotateAndSaveImageAsync",
                                          Qt::QueuedConnection,
                                          Q_ARG(QString, filePath),
                                          Q_ARG(int, 0)); // Trigger processing of accumulated rotation
            }
        }
    });

    watcher->setFuture(future);
}

void ImageLoader::setDesktopWallpaperAsync(const QString &filePath)
{
    {
        QMutexLocker locker(&m_operationsMutex);
        m_pendingOperations++;
    }

    // Run wallpaper setting in background thread
    QFuture<bool> future = QtConcurrent::run([filePath]() {
        return performSetDesktopWallpaper(filePath);
    });

    // Watch for completion
    QFutureWatcher<bool> *watcher = new QFutureWatcher<bool>(this);

    connect(watcher, &QFutureWatcher<bool>::finished, [this, watcher]() {
        bool success = watcher->result();

        {
            QMutexLocker locker(&m_operationsMutex);
            m_pendingOperations--;

            if (m_pendingOperations == 0) {
                emit allOperationsComplete();
            }
        }

        emit wallpaperSetComplete("desktop", success);
        watcher->deleteLater();
    });

    watcher->setFuture(future);
}

void ImageLoader::setLockScreenWallpaperAsync(const QString &filePath)
{
    {
        QMutexLocker locker(&m_operationsMutex);
        m_pendingOperations++;
    }

    // Run wallpaper setting in background thread
    QFuture<bool> future = QtConcurrent::run([filePath]() {
        return performSetLockScreenWallpaper(filePath);
    });

    // Watch for completion
    QFutureWatcher<bool> *watcher = new QFutureWatcher<bool>(this);

    connect(watcher, &QFutureWatcher<bool>::finished, [this, watcher]() {
        bool success = watcher->result();

        {
            QMutexLocker locker(&m_operationsMutex);
            m_pendingOperations--;

            if (m_pendingOperations == 0) {
                emit allOperationsComplete();
            }
        }

        emit wallpaperSetComplete("lockscreen", success);
        watcher->deleteLater();
    });

    watcher->setFuture(future);
}

void ImageLoader::setBothWallpapersAsync(const QString &filePath)
{
    {
        QMutexLocker locker(&m_operationsMutex);
        m_pendingOperations++;
    }

    // Run wallpaper setting in background thread
    QFuture<QPair<bool, bool>> future = QtConcurrent::run([filePath]() {
        return performSetBothWallpapers(filePath);
    });

    // Watch for completion
    QFutureWatcher<QPair<bool, bool>> *watcher = new QFutureWatcher<QPair<bool, bool>>(this);

    connect(watcher, &QFutureWatcher<QPair<bool, bool>>::finished, [this, watcher]() {
        QPair<bool, bool> results = watcher->result();
        bool desktopSuccess = results.first;
        bool lockscreenSuccess = results.second;

        {
            QMutexLocker locker(&m_operationsMutex);
            m_pendingOperations--;

            if (m_pendingOperations == 0) {
                emit allOperationsComplete();
            }
        }

        emit wallpaperSetComplete("desktop", desktopSuccess);
        emit wallpaperSetComplete("lockscreen", lockscreenSuccess);
        emit wallpaperSetComplete("both", desktopSuccess && lockscreenSuccess);
        watcher->deleteLater();
    });

    watcher->setFuture(future);
}

void ImageLoader::cancelPendingRotations(const QString &filePath)
{
    QMutexLocker locker(&m_operationsMutex);
    m_pendingRotations.remove(filePath);
}

bool ImageLoader::hasPendingOperations() const
{
    QMutexLocker locker(&m_operationsMutex);
    return m_pendingOperations > 0;
}

void ImageLoader::waitForPendingOperations()
{
    // Simple spin wait - in a real app you might want something more sophisticated
    while (hasPendingOperations()) {
        QThread::msleep(10);
        QGuiApplication::processEvents();
    }
}

bool ImageLoader::deleteImage(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        return false;
    }

    // Move to trash/recycle bin instead of permanent deletion
    QFile file(localPath);
    return file.moveToTrash();
}

bool ImageLoader::performRotation(const QString &filePath, int angle)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        return false;
    }

    // Load as QPixmap for potentially better performance
    QPixmap pixmap(localPath);
    if (pixmap.isNull()) {
        return false;
    }

    // Quick exit for no rotation
    angle = ((angle % 360) + 360) % 360;
    if (angle == 0) {
        return true;
    }

    // Use QPixmap transformation (potentially hardware accelerated)
    QTransform transform;
    transform.rotate(angle);

    QPixmap rotatedPixmap = pixmap.transformed(transform, Qt::SmoothTransformation);

    // Save directly from QPixmap
    QString format = fileInfo.suffix().toUpper();

    bool success;
    if (format == "JPG" || format == "JPEG") {
        success = rotatedPixmap.save(localPath, "JPEG", 85); // Good quality/speed balance
    } else {
        success = rotatedPixmap.save(localPath);
    }

    return success;
}

bool ImageLoader::performSetDesktopWallpaper(const QString &filePath)
{
#ifdef Q_OS_WIN
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists()) {
        return false;
    }

    std::wstring wPath = localPath.toStdWString();
    return SystemParametersInfoW(SPI_SETDESKWALLPAPER, 0,
                                 (void*)wPath.c_str(),
                                 SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
#else
    Q_UNUSED(filePath)
    return false; // Not supported on this platform
#endif
}

bool ImageLoader::performSetLockScreenWallpaper(const QString &filePath)
{
#ifdef Q_OS_WIN
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists()) {
        return false;
    }

    // Windows 10/11 lock screen wallpaper setting
    QSettings settings("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\PersonalizationCSP",
                       QSettings::NativeFormat);

    settings.setValue("LockScreenImagePath", localPath);
    settings.setValue("LockScreenImageUrl", localPath);
    settings.setValue("LockScreenImageStatus", 1);

    return true;
#else
    Q_UNUSED(filePath)
    return false; // Not supported on this platform
#endif
}

QPair<bool, bool> ImageLoader::performSetBothWallpapers(const QString &filePath)
{
    bool desktopSuccess = performSetDesktopWallpaper(filePath);
    bool lockscreenSuccess = performSetLockScreenWallpaper(filePath);

    return QPair<bool, bool>(desktopSuccess, lockscreenSuccess);
}
