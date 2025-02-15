/*
    Copyright (C) 2011  Martin Gräßlin <mgraesslin@kde.org>
    Copyright (C) 2012  Gregor Taetzner <gregor@freenet.de>
    Copyright (C) 2012  Marco Martin <mart@kde.org>
    Copyright (C) 2013 2014 David Edmundson <davidedmundson@kde.org>
    Copyright 2014 Sebastian Kügler <sebas@kde.org>

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
import QtQuick 2.3
import org.kde.plasma.plasmoid 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import org.kde.plasma.private.kicker 0.1 as Kicker

Item {
    id: root
    Layout.minimumWidth: units.gridUnit * plasmoid.configuration.menuWidth
    Layout.maximumWidth: Layout.minimumWidth

    Layout.minimumHeight: units.gridUnit * plasmoid.configuration.menuHeight
    Layout.maximumHeight: Layout.minimumHeight

    property string previousState
    property bool switchTabsOnHover: plasmoid.configuration.switchTabsOnHover
    property Item currentView: mainTabGroup.currentTab.decrementCurrentIndex ? mainTabGroup.currentTab : mainTabGroup.currentTab.item
    property KickoffButton firstButton: null
    property var configMenuItems
    property var tabPagesModel: []
    property var buttons: []

    property QtObject globalFavorites: rootModelFavorites

    state: "Normal"

    onFocusChanged: {
        header.input.forceActiveFocus();
    }

    function switchToInitial() {
        if (firstButton != null) {
            root.state = "Normal";
            mainTabGroup.currentTab = firstButton.tab;
            tabBar.currentTab = firstButton;
            header.query = ""
        }
    }

    Kicker.DragHelper {
        id: dragHelper

        dragIconSize: units.iconSizes.medium
        onDropped: kickoff.dragSource = null
    }

    Kicker.AppsModel {
        id: rootModel

        autoPopulate: false

        appletInterface: plasmoid

        appNameFormat: plasmoid.configuration.showAppsByName ? 0 : 1
        flat: false
        sorted: plasmoid.configuration.alphaSort
        showSeparators: false
        showTopLevelItems: true

        favoritesModel: Kicker.KAStatsFavoritesModel {
            id: rootModelFavorites
            favorites: plasmoid.configuration.favorites

            onFavoritesChanged: {
                plasmoid.configuration.favorites = favorites;
            }
        }

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kickoff.favorites.instance-" + plasmoid.id)

            if (!plasmoid.configuration.favoritesPortedToKAstats) {
                favoritesModel.portOldFavorites(plasmoid.configuration.favorites);
                plasmoid.configuration.favoritesPortedToKAstats = true;
            }

            rootModel.refresh();
        }
    }

    PlasmaCore.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["PowerDevil"]
    }

    PlasmaCore.Svg {
        id: arrowsSvg

        imagePath: "widgets/arrows"
        size: "16x16"
    }

    Header {
        id: header
    }

    Rectangle {
        id: headerSeparator

        height: Math.floor(units.devicePixelRatio)
        color: theme.textColor
        opacity: 0.2
        width: root.width - 2 * units.gridUnit

        anchors {
            top: header.top
            horizontalCenter: header.horizontalCenter
        }
    }

    Item {
        id: mainArea
        anchors.topMargin: mainTabGroup.state == "top" ? units.smallSpacing : 0

        PlasmaComponents.TabGroup {
            id: mainTabGroup

            anchors {
                fill: parent
            }

            Repeater {
                id: mainTabGroupTabs
                model: root.tabPagesModel
                delegate: PlasmaExtras.ConditionalLoader {
                    parent: mainTabGroup
                    property string pageName:modelData["pageName"]
                    when: buttons.indexOf(tabBar.currentTab) === index;
                    source: Qt.resolvedUrl(modelData["source"])
                }
            }

            PlasmaExtras.ConditionalLoader {
                id: searchPage
                when: root.state == "Search"
                //when: mainTabGroup.currentTab == searchPage || root.state == "Search"
                source: Qt.resolvedUrl("SearchView.qml")
            }

            state: {
                switch (plasmoid.location) {
                case PlasmaCore.Types.LeftEdge:
                    return LayoutMirroring.enabled ? "right" : "left";
                case PlasmaCore.Types.TopEdge:
                    return "top";
                case PlasmaCore.Types.RightEdge:
                    return LayoutMirroring.enabled ? "left" : "right";
                case PlasmaCore.Types.BottomEdge:
                default:
                    return "bottom";
                }
            }
            states: [
                State {
                    name: "left"
                    AnchorChanges {
                        target: header
                        anchors {
                            left: root.left
                            top: undefined
                            right: root.right
                            bottom: root.bottom
                        }
                    }
                    PropertyChanges {
                        target: header
                        width: header.implicitWidth
                    }
                    AnchorChanges {
                        target: mainArea
                        anchors {
                            left: tabBar.right
                            top: root.top
                            right: root.right
                            bottom: header.top
                        }
                    }
                    PropertyChanges {
                        target: tabBar
                        width: (tabBar.opacity == 0) ? 0 : units.gridUnit * 5
                    }
                    AnchorChanges {
                        target: tabBar
                        anchors {
                            left: root.left
                            top: root.top
                            right: undefined
                            bottom: header.top
                        }
                    }
                    PropertyChanges {
                        target:tabBarSeparator
                        width: Math.floor(units.devicePixelRatio)
                    }
                    AnchorChanges {
                        target: tabBarSeparator
                        anchors {
                            left: tabBar.right
                            top: tabBar.top
                            bottom:tabBar.bottom
                        }
                    }
                },
                State {
                    name: "top"
                    AnchorChanges {
                        target: header
                        anchors {
                            left: root.left
                            top: undefined
                            right: root.right
                            bottom: root.bottom
                        }
                    }
                    PropertyChanges {
                        target: header
                        height: header.implicitHeight
                    }
                    AnchorChanges {
                        target: mainArea
                        anchors {
                            left: root.left
                            top: tabBar.bottom
                            right: root.right
                            bottom: header.top
                        }
                    }
                    PropertyChanges {
                        target: tabBar
                        height: (tabBar.opacity == 0) ? 0 : units.gridUnit * 5
                    }
                    AnchorChanges {
                        target: tabBar
                        anchors {
                            left: root.left
                            top: root.top
                            right: root.right
                            bottom: undefined
                        }
                    }
                    PropertyChanges {
                        target:tabBarSeparator
                        height: Math.floor(units.devicePixelRatio)
                    }
                    AnchorChanges {
                        target: tabBarSeparator
                        anchors {
                            left: tabBar.left
                            right: tabBar.right
                            top: tabBar.bottom
                        }
                    }
                },
                State {
                    name: "right"
                    AnchorChanges {
                        target: header
                        anchors {
                            left: root.left
                            top: undefined
                            right: root.right
                            bottom: root.bottom
                        }
                    }
                    PropertyChanges {
                        target: header
                        width: header.implicitWidth
                    }
                    AnchorChanges {
                        target: mainArea
                        anchors {
                            left: root.left
                            top: root.top
                            right: tabBar.left
                            bottom: header.top
                        }
                    }
                    PropertyChanges {
                        target: tabBar
                        width: (tabBar.opacity == 0) ? 0 : units.gridUnit * 5
                    }
                    AnchorChanges {
                        target: tabBar
                        anchors {
                            left: undefined
                            top: root.top
                            right: root.right
                            bottom: header.top
                        }
                    }
                    PropertyChanges {
                        target:tabBarSeparator
                        width:  Math.floor(units.devicePixelRatio)
                    }
                    AnchorChanges {
                        target: tabBarSeparator
                        anchors {
                            right: tabBar.left
                            top: tabBar.top
                            bottom: tabBar.bottom
                        }
                    }
                },
                State {
                    name: "bottom"
                    AnchorChanges {
                        target: header
                        anchors {
                            left: root.left
                            top: root.top
                            right: root.right
                            bottom: undefined
                        }
                    }
                    PropertyChanges {
                        target: header
                        height: header.implicitHeight
                    }
                    AnchorChanges {
                        target: headerSeparator
                        anchors {
                            top: undefined
                            bottom: header.bottom
                        }
                    }
                    AnchorChanges {
                        target: mainArea
                        anchors {
                            left: root.left
                            top: header.bottom
                            right: root.right
                            bottom: tabBar.top
                        }
                    }
                    PropertyChanges {
                        target: tabBar
                        height: (tabBar.opacity == 0) ? 0 : units.gridUnit * 5
                    }
                    AnchorChanges {
                        target: tabBar
                        anchors {
                            left: root.left
                            top: undefined
                            right: root.right
                            bottom: root.bottom
                        }
                    }
                    PropertyChanges {
                        target:tabBarSeparator
                        height: Math.floor(units.devicePixelRatio)
                    }
                    AnchorChanges {
                        target: tabBarSeparator
                        anchors {
                            bottom: tabBar.top
                            left: tabBar.left
                            right: tabBar.right
                        }
                    }
                }
            ]
        } // mainTabGroup
    }

    PlasmaComponents.TabBar {
        id: tabBar

        property int count: 5 // updated in createButtons()

        Behavior on width {
            NumberAnimation { duration: units.longDuration; easing.type: Easing.InQuad; }
            enabled: plasmoid.expanded
        }
        Behavior on height {
            NumberAnimation { duration: units.longDuration; easing.type: Easing.InQuad; }
            enabled: plasmoid.expanded
        }

        tabPosition: {
            switch (plasmoid.location) {
            case PlasmaCore.Types.TopEdge:
                return Qt.TopEdge;
            case PlasmaCore.Types.LeftEdge:
                return Qt.LeftEdge;
            case PlasmaCore.Types.RightEdge:
                return Qt.RightEdge;
            default:
                return Qt.BottomEdge;
            }
        }

        onCurrentTabChanged: header.input.forceActiveFocus();

        Connections {
            target: plasmoid
            onExpandedChanged: {
                if(menuItemsChanged()) {
                    createButtons();
                }
                if (!expanded) {
                    switchToInitial();
                }
            }
        }
    } // tabBar

    Rectangle {
        id: tabBarSeparator

        color: theme.textColor
        opacity: 0.2
    }

    MouseArea {
        anchors.fill: tabBar

        property var oldPos: null

        hoverEnabled: root.switchTabsOnHover

        onExited: {
            // Reset so we switch immediately when MouseArea is entered
            // freshly, e.g. from the panel.
            oldPos = null;

            clickTimer.stop();
        }

        onPositionChanged: {
            // Reject multiple events with the same coordinates that QQuickWindow
            // synthesizes.
            if (oldPos === Qt.point(mouse.x, mouse.y)) {
                return;
            }

            var button = tabBar.layout.childAt(mouse.x, mouse.y);

            if (!button || button.objectName !== "KickoffButton") {
                clickTimer.stop();

                return;
            }

            // Switch immediately when MouseArea was freshly entered, e.g.
            // from the panel.
            if (oldPos === null) {
                oldPos = Qt.point(mouse.x, mouse.y);

                clickTimer.stop();
                button.clicked();

                return;
            }

            var dx  = (mouse.x - oldPos.x);
            var dy  = (mouse.y - oldPos.y);

            // Check Manhattan length against drag distance to get a decent
            // pointer motion vector.
            if ((Math.abs(dx) + Math.abs(dy)) > Qt.styleHints.startDragDistance) {
                if (tabBar.currentTab !== button) {
                    var tabBarPos = mapToItem(tabBar, oldPos.x, oldPos.y);
                    oldPos = Qt.point(mouse.x, mouse.y);

                    var angleMouseMove = Math.atan2(dy, dx) * 180 / Math.PI;
                    var angleToCornerA = 0;
                    var angleToCornerB = 0;

                    switch (plasmoid.location) {
                        case PlasmaCore.Types.TopEdge: {
                            angleToCornerA = Math.atan2(tabBar.height - tabBarPos.y, 0 - tabBarPos.x);
                            angleToCornerB = Math.atan2(tabBar.height - tabBarPos.y, tabBar.width - tabBarPos.x);

                            break;
                        }
                        case PlasmaCore.Types.LeftEdge: {
                            angleToCornerA = Math.atan2(0 - tabBarPos.y, tabBar.width - tabBarPos.x);
                            angleToCornerB = Math.atan2(tabBar.height - tabBarPos.y, tabBar.width - tabBarPos.x);

                            break;
                        }
                        case PlasmaCore.Types.RightEdge: {
                            angleToCornerA = Math.atan2(0 - tabBarPos.y, 0 - tabBarPos.x);
                            angleToCornerB = Math.atan2(tabBar.height - tabBarPos.y, 0 - tabBarPos.x);

                            break;
                        }
                        // PlasmaCore.Types.BottomEdge
                        default: {
                            angleToCornerA = Math.atan2(0 - tabBarPos.y, 0 - tabBarPos.x);
                            angleToCornerB = Math.atan2(0 - tabBarPos.y, tabBar.width - tabBarPos.x);
                        }
                    }

                    // Degrees are nicer to debug than radians.
                    angleToCornerA = angleToCornerA * 180 / Math.PI;
                    angleToCornerB = angleToCornerB * 180 / Math.PI;

                    var lower = Math.min(angleToCornerA, angleToCornerB);
                    var upper = Math.max(angleToCornerA, angleToCornerB);

                    // If the motion vector is outside the angle range from oldPos to the
                    // relevant tab bar corners, switch immediately. Otherwise start the
                    // timer, which gets aborted should the pointer exit the tab bar
                    // early.
                    var inRange = (lower < angleMouseMove == angleMouseMove < upper);

                    // Mirror-flip.
                    if (plasmoid.location === PlasmaCore.Types.RightEdge ? inRange : !inRange) {
                        clickTimer.stop();
                        button.clicked();

                        return;
                    } else {
                        clickTimer.pendingButton = button;
                        clickTimer.start();
                    }
                } else {
                    oldPos = Qt.point(mouse.x, mouse.y);
                }
            }
        }

        onClicked: {
            clickTimer.stop();

            var button = tabBar.layout.childAt(mouse.x, mouse.y);

            if (!button || button.objectName !== "KickoffButton") {
                return;
            }

            button.clicked();
        }

        Timer {
            id: clickTimer

            property Item pendingButton: null

            interval: 250

            onTriggered: {
                if (pendingButton) {
                    pendingButton.clicked();
                }
            }
        }
    }

    Keys.forwardTo: [tabBar.layout]

    Keys.onPressed: {

        if (mainTabGroup.currentTab.pageName == "applicationsPage") {
            if (event.key !== Qt.Key_Tab) {
                root.state = "Applications";
            }
        } else if (mainTabGroup.currentTab.pageName == "favoritesPage") {
            if (event.key !== Qt.Key_Tab) {
                root.state = "Favorites";
            }
        }

        switch(event.key) {
            case Qt.Key_Up: {
                currentView.decrementCurrentIndex();
                event.accepted = true;
                break;
            }
            case Qt.Key_Down: {
                currentView.incrementCurrentIndex();
                event.accepted = true;
                break;
            }
            case Qt.Key_Left: {
                if (header.input.focus && header.state == "query") {
                    break;
                }
                if (!currentView.deactivateCurrentIndex()) {
                    if (root.state == "Applications" || root.state == "Favorites") {
                        switchToPreviousTab();
                    }
                    root.state = "Normal";
                }
                event.accepted = true;
                break;
            }
            case Qt.Key_Right: {
                if (header.input.focus && header.state == "query") {
                    break;
                }
                if (!currentView.activateCurrentIndex()) {
                    if (root.state == "Favorites") {
                        switchToNextTab();
                        root.state = "Normal";
                    }
                }
                event.accepted = true;
                break;
            }
            case Qt.Key_Tab: {
                root.state == "Applications" ? root.state = "Normal" : root.state = "Applications";
                root.state == "Favorites" ? root.state = "Normal" : root.state = "Favorites";
                event.accepted = true;
                break;
            }
            case Qt.Key_Enter:
            case Qt.Key_Return: {
                currentView.activateCurrentIndex(1);
                event.accepted = true;
                break;
            }
            case Qt.Key_Escape: {
                if (header.state != "query") {
                    plasmoid.expanded = false;
                } else {
                    header.query = "";
                }
                event.accepted = true;
                break;
            }
            case Qt.Key_Menu: {
                currentView.openContextMenu();
                event.accepted = true;
                break;
            }
            default:
                if (!header.input.focus) {
                    header.input.forceActiveFocus();
                }
        }
    }

    states: [
        State {
            name: "Normal"
            PropertyChanges {
                target: root
                Keys.forwardTo: [tabBar.layout]
            }
            PropertyChanges {
                target: tabBar
                //Set the opacity and NOT the visibility, as visibility is recursive
                //and this binding would be executed also on popup show/hide
                //as recommended by the docs: http://doc.qt.io/qt-5/qml-qtquick-item.html#visible-prop
                //plus, it triggers https://bugreports.qt.io/browse/QTBUG-66907
                //in which a mousearea may think it's under the mouse while it isn't
                opacity: tabBar.count > 1 ? 1 : 0
            }
        },
        State {
            name: "Applications"
            PropertyChanges {
                target: root
                Keys.forwardTo: [root]
            }
            PropertyChanges {
                target: tabBar
                opacity: tabBar.count > 1 ? 1 : 0
            }
        },
        State {
            name: "Favorites"
            PropertyChanges {
                target: root
                Keys.forwardTo: [root]
            }
            PropertyChanges {
                target: tabBar
                opacity: tabBar.count > 1 ? 1 : 0
            }
        },
        State {
            name: "Search"
            PropertyChanges {
                target: tabBar
                opacity: 0
            }
            PropertyChanges {
                target: mainTabGroup
                currentTab: searchPage
            }
            PropertyChanges {
                target: root
                Keys.forwardTo: [root]
            }
        }
    ] // states

    function getTabDefinition(name) {
        switch(name) {
        case "bookmark":
            return {source: "FavoritesView.qml", pageName: "favoritesPage"};
        case "application":
            return {source: "ApplicationsView.qml", pageName: "applicationsPage"};
        case "computer":
            return {source: "ComputerView.qml", pageName: "systemPage"};
        case "used":
            return {source: "RecentlyUsedView.qml", pageName: "recentlyUsedPage"};
        case "oftenUsed":
            return {source: "OftenUsedView.qml", pageName: "oftenUsedPage"};
        case "leave":
            return {source: "LeaveView.qml", pageName: "leavePage"};
        }
    }

    function getButtonDefinition(name) {
        switch(name) {
        case "bookmark":
            return {id: "bookmarkButton", iconSource: "bookmarks", text: i18n("Favorites")};
        case "application":
            return {id: "applicationButton", iconSource: "applications-other", text: i18n("Applications")};
        case "computer":
            return {id: "computerButton", iconSource: pmSource.data["PowerDevil"] && pmSource.data["PowerDevil"]["Is Lid Present"] ? "computer-laptop" : "computer", text: i18n("Computer")};
        case "used":
            return {id: "usedButton", iconSource: "view-history", text: i18n("History")};
        case "oftenUsed":
            return {id: "usedButton", iconSource: "office-chart-pie", text: i18n("Often Used")};
        case "leave":
            return {id: "leaveButton", iconSource: "system-log-out", text: i18n("Leave")};
        }
    }

    Component {
        id: kickoffButton
        KickoffButton {}
    }


    Component.onCompleted: {
        createButtons();
    }

    function getEnabled(configuration) {
        var res = [];
        for(var i = 0; i < configuration.length; i++) {
            var confItemName = configuration[i].substring(0, configuration[i].indexOf(":"));
            var confItemEnabled = configuration[i].substring(configuration[i].length-1) === "t";
            if(confItemEnabled) {
                res.push(confItemName);
            }
        }

        return res;
    }

    function createButtons() {
        configMenuItems = plasmoid.configuration.menuItems;
        var menuItems = getEnabled(plasmoid.configuration.menuItems);
        tabBar.count = menuItems.length

        // remove old menu items
        root.buttons = [];
        root.tabPagesModel = [];
        for(var i = tabBar.layout.children.length -1; i >= 0; i--)  {
            if(tabBar.layout.children[i].objectName === "KickoffButton") {
                tabBar.layout.children[i].destroy();
            }
        }
        // setup tab pages model
        for (var i = 0; i < menuItems.length; i++) {
            var props = getTabDefinition(menuItems[i]);
            root.tabPagesModel.push(props);
        }
        mainTabGroupTabs.model = root.tabPagesModel; // force update

        // setup buttons
        for (var i = 0; i < menuItems.length; i++) {
            var props = getButtonDefinition(menuItems[i]);
            // add tab reference so that tabs would change
            props["tab"] = mainTabGroupTabs.itemAt(i);
            var button = kickoffButton.createObject(tabBar.layout, props);
            // keeping a list of buttons is more simple
            root.buttons.push(button);
            if (i === 0) {
                firstButton = button;
                switchToInitial();
            }
        }
    }

    function getCurrentTabIndex() {
        return buttons.indexOf(tabBar.currentTab);
    }

    function switchToTab(index) {
        var button = buttons[index];
        mainTabGroup.currentTab = button.tab;
        tabBar.currentTab = button;
    }

    function switchToNextTab() {
        var index = getCurrentTabIndex();
        switchToTab(++index % tabBar.count);
    }

    function switchToPreviousTab() {
        var index = getCurrentTabIndex();
        if (--index < 0) {
            index = tabBar.count - 1;
        }
        switchToTab(index);
    }

    function menuItemsChanged() {
        if(configMenuItems.length !== plasmoid.configuration.menuItems.length) {
            return true;
        }

        for(var i = 0; i < configMenuItems.length; i++) {
            if(configMenuItems[i] !== plasmoid.configuration.menuItems[i]) {
                return true;
            }
        }
        return false;
    }
}
