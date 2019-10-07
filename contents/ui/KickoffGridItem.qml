/*
    Copyright (C) 2011  Martin Gräßlin <mgraesslin@kde.org>
    Copyright (C) 2012  Gregor Taetzner <gregor@freenet.de>
    Copyright 2014 Sebastian Kügler <sebas@kde.org>
    Copyright (C) 2015-2018  Eike Hein <hein@kde.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/
import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.draganddrop 2.0

import "code/tools.js" as Tools

Item {
    id: gridItem

    width: GridView.view.cellWidth
    height: implicitHeight

    implicitWidth: plasmoid.configuration.favoritesIconSize + (25 * units.smallSpacing) // limit minimum width so that at least some letters are visible
    implicitHeight: (plasmoid.configuration.favoritesEnableSubtitles)
            ? (units.smallSpacing * 2) + Math.max(plasmoid.configuration.favoritesIconSize, titleElement.implicitHeight + subTitleElement.implicitHeight)
            : (units.smallSpacing * 2) + Math.max(plasmoid.configuration.favoritesIconSize, titleElement.implicitHeight)

    signal reset
    signal actionTriggered(string actionId, variant actionArgument)
    signal aboutToShowActionMenu(variant actionMenu)
    signal addBreadcrumb(var model, string title)

    readonly property int itemIndex: model.index
    readonly property string url: model.url || ""
    readonly property var decoration: model.decoration || ""

    property bool dropEnabled: false
    property bool appView: false
    property bool modelChildren: model.hasChildren || false
    property bool isCurrent: gridItem.GridView.view.currentIndex === index;
    property bool showAppsByName: plasmoid.configuration.showAppsByName

    property bool hasActionList: ((model.favoriteId !== null)
        || (("hasActionList" in model) && (model.hasActionList === true)))
    property Item menu: actionMenu

    onAboutToShowActionMenu: {
        var actionList = hasActionList ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, GridView.view.model.favoritesModel, model.favoriteId);
    }

    onActionTriggered: {
        if (Tools.triggerAction(GridView.view.model, model.index, actionId, actionArgument) === true) {
            // plasmoid.expanded = false;
            // it gets collapsed when opening a new window
            // but it won't collapse if user opens a new konsole tab etc
        }

        if (actionId.indexOf("_kicker_favorite_") === 0) {
            switchToInitial();
        }
    }

    function activate() {
        var view = gridItem.GridView.view;

        if (model.hasChildren) {
            var childModel = view.model.modelForRow(index);

            gridItem.addBreadcrumb(childModel, display);
            view.model = childModel;
        } else {
            view.model.trigger(index, "", null);
            plasmoid.expanded = false;
            gridItem.reset();
        }
    }

    function openActionMenu(x, y) {
        aboutToShowActionMenu(actionMenu);
        actionMenu.visualParent = gridItem;
        actionMenu.open(x, y);
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: {
            actionTriggered(actionId, actionArgument);
        }
    }

    PlasmaCore.IconItem {
        id: elementIcon

        anchors {
            left: parent.left
            leftMargin: units.smallSpacing * 6
            verticalCenter: parent.verticalCenter
        }
        width: height
        height: plasmoid.configuration.favoritesIconSize

        animated: false
        usesPlasmaTheme: false

        source: model.decoration
    }

    PlasmaComponents.Label {
        id: titleElement

        y: (subTitleElement.visible)
                ? Math.round((parent.height - titleElement.height - ((subTitleElement.text != "") ? subTitleElement.implicitHeight : 0)) / 2)
                : Math.round((parent.height - titleElement.height) / 2)

        anchors {
            //bottom: elementIcon.verticalCenter
            left: elementIcon.right
            right: arrow.left
            leftMargin: units.smallSpacing * 4
            rightMargin: 0 //units.smallSpacing * 6 // TODO: this depends on if we need an "arrow" item in the gridview
        }
        height: implicitHeight //undo PC2 height override, remove when porting to PC3
        // TODO: games should always show the by name!
        text: model.display
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
    }

    PlasmaComponents.Label {
        id: subTitleElement

        visible: (plasmoid.configuration.favoritesEnableSubtitles === true)

        anchors {
            left: titleElement.left
            right: arrow.right
            top: titleElement.bottom
        }
        height: implicitHeight

        text: model.description
        opacity: isCurrent ? 0.8 : 0.6
        font.pointSize: theme.smallestFont.pointSize
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignLeft
    }

    PlasmaCore.SvgItem {
        id: arrow

        anchors {
            right: parent.right
            rightMargin: units.smallSpacing * 6
            verticalCenter: parent.verticalCenter
        }

        width: visible ? units.iconSizes.small : 0
        height: width

        visible: (model.hasChildren === true)
        opacity: (gridItem.GridView.view.currentIndex === index) ? 1.0 : 0.4

        svg: arrowsSvg
        elementId: (Qt.application.layoutDirection == Qt.RightToLeft) ? "left-arrow" : "right-arrow"
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu();
        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return) && !modelChildren) {
            if (!modelChildren) {
                event.accepted = true;
                gridItem.activate();
            }
        }
    }

    state: (plasmoid.configuration.favoritesLabelsPosition == "right") ? "" : plasmoid.configuration.favoritesLabelsPosition

    states: [
        State {
            name: "hide"
            PropertyChanges {
                target: gridItem
                implicitWidth: plasmoid.configuration.favoritesIconSize + elementIcon.anchors.leftMargin + elementIcon.anchors.rightMargin
                implicitHeight: (units.smallSpacing * 2) + plasmoid.configuration.favoritesIconSize
            }
            AnchorChanges {
                target: elementIcon
                anchors {
                    right: elementIcon.parent.right
                }
            }
            PropertyChanges {
                target: elementIcon
                anchors.rightMargin: elementIcon.anchors.leftMargin
                height: plasmoid.configuration.favoritesIconSize
                width: height
            }
            PropertyChanges {
                target: titleElement
                visible: false
            }
            PropertyChanges {
                target: subTitleElement
                visible: false
            }
        },
        State {
            name: "bottom"
            PropertyChanges {
                target: gridItem
                implicitWidth: plasmoid.configuration.favoritesIconSize + elementIcon.anchors.leftMargin + elementIcon.anchors.rightMargin
                implicitHeight: (plasmoid.configuration.favoritesEnableSubtitles === true)
                        ? elementIcon.anchors.topMargin + plasmoid.configuration.favoritesIconSize + (units.smallSpacing * 1)
                            + titleElement.implicitHeight + subTitleElement.implicitHeight
                        : elementIcon.anchors.topMargin + plasmoid.configuration.favoritesIconSize + (units.smallSpacing * 2)
                            + titleElement.implicitHeight
            }
            AnchorChanges {
                target: elementIcon
                anchors {
                    right: elementIcon.parent.right
                    top: elementIcon.parent.top
                    verticalCenter: undefined
                }
            }
            PropertyChanges {
                target: elementIcon
                anchors.topMargin: 3 * units.smallSpacing
                anchors.rightMargin: elementIcon.anchors.leftMargin
                height: plasmoid.configuration.favoritesIconSize
                width: height
            }
            AnchorChanges {
                target: titleElement
                anchors {
                    top: elementIcon.bottom
                    left: titleElement.parent.left
                }
            }
            PropertyChanges {
                target: titleElement
                horizontalAlignment: Text.AlignHCenter
                anchors.leftMargin: elementIcon.anchors.leftMargin
                y: 0
            }
            PropertyChanges {
                target: subTitleElement
                horizontalAlignment: Text.AlignHCenter
            }
        }
    ]
} // gridItem
