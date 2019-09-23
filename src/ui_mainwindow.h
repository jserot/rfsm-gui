/**********************************************************************/
/*                                                                    */
/*              This file is part of the RFSM package                 */
/*                                                                    */
/*  Copyright (c) 2018-present, Jocelyn SEROT.  All rights reserved.  */
/*                                                                    */
/*  This source code is licensed under the license found in the       */
/*  LICENSE file in the root directory of this source tree.           */
/*                                                                    */
/**********************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QButtonGroup>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QTreeView>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralWidget;
    QVBoxLayout *vLayout;
    QHBoxLayout *hLayout;
    QPushButton *openProjectButton;
    QPushButton *openFileButton;
    QPushButton *newFileButton;
    //QPushButton *saveFileButton;
    //QPushButton *saveAllButton;
    QSpacerItem *hSpacer;
    QPushButton *compileDotFileButton;
    QPushButton *compileCTaskFileButton;
    QPushButton *compileSystemcFileButton;
    QPushButton *compileVHDLFileButton;
    QPushButton *compileDotProjectButton;
    QPushButton *compileCTaskProjectButton;
    QPushButton *compileSystemcProjectButton;
    QPushButton *compileVHDLProjectButton;
    QPushButton *runSimButton;
    QSplitter *vSplitter;
    QSplitter *hSplitter;
    QTreeView *treeView;
    QTabWidget *filesTab[2];
    QTextEdit *logText;
    QMenuBar *menuBar;
    QAction *actionNewFile;
    QAction *actionOpenFile;
    QAction *actionSaveCurrentFile;
    QAction *actionSaveCurrentFileAs;
    QAction *actionCloseFile;
    QAction *actionCloseResFiles;
    QAction *actionCloseAllFiles;
    QAction *actionAbout;
    QAction *actionQuit;
    QAction *actionNewProject;
    QAction *actionOpenProject;
    QAction *actionAddCurrentFileToProject;
    QAction *actionAddFileToProject;
    QAction *actionEditProject;
    QAction *actionSaveProject;
    QAction *actionSaveProjectAs;
    QAction *actionCloseProject;
    QAction *actionBuildDotFile;
    QAction *actionBuildCTaskFile;
    QAction *actionBuildSystemCFile;
    QAction *actionBuildVHDLFile;
    QAction *actionBuildDotProject;
    QAction *actionBuildCTaskProject;
    QAction *actionBuildSystemCProject;
    QAction *actionBuildVHDLProject;
    QAction *actionRunSim;
    QAction *actionCopy;
    QAction *actionCut;
    QAction *actionPaste;
    QAction *actionSelect;
    QAction *actionZoomIn;
    QAction *actionZoomOut;
    QAction *actionNormalSize;
    QAction *actionFitToWindow;
    QAction *actionPathConfig;
    QAction *actionGeneralOptions;
    QAction *actionFontConfig;

    void setupUi(QMainWindow *MainWindow);
    void createMenus(QMainWindow *MainWindow);
    void retranslateUi(QMainWindow *MainWindow) {
      MainWindow->setWindowTitle(QApplication::translate("MainWindow", "Rfsm", 0));
      } 
};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
}

QT_END_NAMESPACE

#endif 
