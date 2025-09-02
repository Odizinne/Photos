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

signals:
    void imageRotationComplete(const QString &filePath, bool success);
    void allOperationsComplete();

private:
    explicit ImageLoader(QObject *parent = nullptr);
    static ImageLoader* s_instance;

    QString m_initialImagePath;
    mutable QMutex m_operationsMutex;
    int m_pendingOperations = 0;

    // Track accumulated rotation per file
    QHash<QString, int> m_pendingRotations;

    // Helper function for threaded rotation
    static bool performRotation(const QString &filePath, int angle);
};

#endif // IMAGELOADER_H
