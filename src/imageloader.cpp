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
        m_pendingOperations++;
    }

    // Run rotation in background thread
    QFuture<bool> future = QtConcurrent::run([this, filePath, angle]() {
        return performRotation(filePath, angle);
    });

    // Watch for completion
    QFutureWatcher<bool> *watcher = new QFutureWatcher<bool>(this);

    connect(watcher, &QFutureWatcher<bool>::finished, [this, watcher, filePath]() {
        bool success = watcher->result();

        {
            QMutexLocker locker(&m_operationsMutex);
            m_pendingOperations--;
            if (m_pendingOperations == 0) {
                emit allOperationsComplete();
            }
        }

        emit imageRotationComplete(filePath, success);
        watcher->deleteLater();
    });

    watcher->setFuture(future);
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
