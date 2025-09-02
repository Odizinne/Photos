#ifndef IMAGELOADER_H
#define IMAGELOADER_H

#include <QObject>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QFileInfo>
#include <QUrl>
#include <QImage>
#include <QPixmap>
#include <QTransform>
#include <QThread>
#include <QMutex>
#include <QFuture>
#include <QFutureWatcher>
#include <QtConcurrent/QtConcurrentRun>
#include <QFile>
#include <QSettings>
#include <QPair>
#include <QClipboard>
#include <QMimeData>
#include <QStandardPaths>
#include <QDateTime>
#include <QDir>

#ifdef Q_OS_WIN
#include <Windows.h>
#include <ShlObj.h>
#endif

class ImageLoader : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static ImageLoader* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static ImageLoader* instance();

    Q_INVOKABLE QString getInitialImagePath() const;
    Q_INVOKABLE qint64 getFileSize(const QString &filePath);
    Q_INVOKABLE void rotateAndSaveImageAsync(const QString &filePath, int angle);
    Q_INVOKABLE bool hasPendingOperations() const;
    Q_INVOKABLE void waitForPendingOperations();
    Q_INVOKABLE bool deleteImage(const QString &filePath);
    Q_INVOKABLE void cancelPendingRotations(const QString &filePath);
    Q_INVOKABLE void setDesktopWallpaperAsync(const QString &filePath);
    Q_INVOKABLE void setLockScreenWallpaperAsync(const QString &filePath);
    Q_INVOKABLE void setBothWallpapersAsync(const QString &filePath);
    Q_INVOKABLE void copyImageToClipboard(const QString &filePath);
    Q_INVOKABLE void copyPathToClipboard(const QString &filePath);
    Q_INVOKABLE QString pasteImageFromClipboard();

signals:
    void imageRotationComplete(const QString &filePath, bool success);
    void allOperationsComplete();
    void wallpaperSetComplete(const QString &type, bool success);

private:
    explicit ImageLoader(QObject *parent = nullptr);
    static ImageLoader* s_instance;

    QString m_initialImagePath;
    mutable QMutex m_operationsMutex;
    int m_pendingOperations = 0;

    QHash<QString, int> m_pendingRotations;

    static bool performRotation(const QString &filePath, int angle);

    static bool performSetDesktopWallpaper(const QString &filePath);
    static bool performSetLockScreenWallpaper(const QString &filePath);
    static QPair<bool, bool> performSetBothWallpapers(const QString &filePath);
};

#endif // IMAGELOADER_H
