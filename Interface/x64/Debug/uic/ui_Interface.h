/********************************************************************************
** Form generated from reading UI file 'Interface.ui'
**
** Created by: Qt User Interface Compiler version 6.5.1
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_INTERFACE_H
#define UI_INTERFACE_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QToolBar>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_InterfaceClass
{
public:
    QMenuBar *menuBar;
    QToolBar *mainToolBar;
    QWidget *centralWidget;
    QStatusBar *statusBar;

    void setupUi(QMainWindow *InterfaceClass)
    {
        if (InterfaceClass->objectName().isEmpty())
            InterfaceClass->setObjectName("InterfaceClass");
        InterfaceClass->resize(600, 400);
        menuBar = new QMenuBar(InterfaceClass);
        menuBar->setObjectName("menuBar");
        InterfaceClass->setMenuBar(menuBar);
        mainToolBar = new QToolBar(InterfaceClass);
        mainToolBar->setObjectName("mainToolBar");
        InterfaceClass->addToolBar(mainToolBar);
        centralWidget = new QWidget(InterfaceClass);
        centralWidget->setObjectName("centralWidget");
        InterfaceClass->setCentralWidget(centralWidget);
        statusBar = new QStatusBar(InterfaceClass);
        statusBar->setObjectName("statusBar");
        InterfaceClass->setStatusBar(statusBar);

        retranslateUi(InterfaceClass);

        QMetaObject::connectSlotsByName(InterfaceClass);
    } // setupUi

    void retranslateUi(QMainWindow *InterfaceClass)
    {
        InterfaceClass->setWindowTitle(QCoreApplication::translate("InterfaceClass", "Interface", nullptr));
    } // retranslateUi

};

namespace Ui {
    class InterfaceClass: public Ui_InterfaceClass {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_INTERFACE_H
