/*
    Copyright (C) 2011  Martin Gräßlin <mgraesslin@kde.org>
    Copyright (C) 2012  Gregor Taetzner <gregor@freenet.de>
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
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents


FocusScope {
    id: view

    signal reset
    signal addBreadcrumb(var model, string title)

    readonly property Item gridView: gridView
    readonly property Item scrollArea: scrollArea

    property bool showAppsByName: true
    property bool appView: false

    property bool horizontalWrap: true

    property alias model: gridView.model
    property alias delegate: gridView.delegate
    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias count: gridView.count
    property alias interactive: gridView.interactive
    property alias contentHeight: gridView.contentHeight

    property alias move: gridView.move
    property alias moveDisplaced: gridView.moveDisplaced

    function deactivateCurrentIndex() {
        if (!horizontalWrap && gridView.currentColumn() == 1) {
            return false; // make arrow keys move to other tabs
        }
        gridView.moveCurrentIndexLeft();
        return true;
    }

    function activateCurrentIndex(start) {
        if (start) {
            currentItem.activate();
        } else {
            if (!horizontalWrap && gridView.currentColumn() == gridView.totalColumns()) {
                return false;
            }
            gridView.moveCurrentIndexRight();
            return true;
        }
    }

    function incrementCurrentIndex() {
        // work around GridView selecting the second item (when flow is FlowLeftToRight)
        // on the first increment (when the user open menu and presses the down arrow key)
        if (gridView.currentIndex == -1) {
            gridView.currentIndex = 0;
        } else {
            gridView.moveCurrentIndexDown();
        }
    }

    function decrementCurrentIndex() {
        gridView.moveCurrentIndexUp();
    }

    Connections {
        target: plasmoid

        onExpandedChanged: {
            if (!expanded) {
                gridView.positionViewAtBeginning();
            }
        }
    }

    PlasmaExtras.ScrollArea {
        id: scrollArea
        frameVisible: false
        anchors.fill: parent

        GridView {
            id: gridView

            focus: true
            keyNavigationWraps: true
            boundsBehavior: Flickable.StopAtBounds

            flow: plasmoid.configuration.favoritesFlow

            currentIndex: -1

            cellWidth: Math.floor(width / columnsOnScreen)
            cellHeight: (count === 0) ? 0 : itemAt(0,0).implicitHeight

            // TODO: make it prettier
            // this is really the best i can do. putting it into a function
            // requires many onChanged handlers and it's not always
            // updated in the right order after gridcells, so it would require putting
            // onChanged handlers there too.
            // When it's done like this, Qt binds everthing in the right order automatically
            // but only if those values for  count == 0 are right.
            // and this fragility makes me think this is, too, a wrong way
            readonly property int rowsOnScreen: (count === 0) ? 0 : Math.max(1, Math.floor(height / cellHeight))
            readonly property int filledColumns: Math.ceil(count / rowsOnScreen)
            readonly property int maxColumns: (count === 0) ? 0 : Math.floor(width / itemAt(0,0).implicitWidth)
            readonly property int columnsOnScreen: Math.min(maxColumns, plasmoid.configuration.favoritesColumns, filledColumns)

            function totalColumns() {
                return (flow == GridView.FlowLeftToRight) ? columnsOnScreen : filledColumns
            }
            function currentColumn() {
                if (flow == GridView.FlowLeftToRight) {
                    return currentIndex % columnsOnScreen + 1;
                } else {
                    return Math.floor(currentIndex / rowsOnScreen) + 1;
                }
            }

            highlight: KickoffHighlight {}
            highlightMoveDuration : 0

            delegate: KickoffGridItem {
                id: delegateItem

                appView: view.appView
                showAppsByName: view.showAppsByName

                onReset: view.reset()
                onAddBreadcrumb: view.addBreadcrumb(model, title)
            }
        }

    }

    MouseArea {
        anchors.left: parent.left

        width: scrollArea.viewport.width
        height: parent.height

        id: mouseArea

        property Item pressed: null
        property int pressX: -1
        property int pressY: -1

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onWheel: {
            // when flow is set to horizontal, set wheel to scroll horizontally
            // without requiring the user to hold alt
            var movement = units.smallSpacing * wheel.angleDelta.y / 4; 
            //TODO: this "/ 4" is completely arbitrary so it may not be the right solution
            //TODO: rarely when changing label position it bugs out and scrolls sub 0 i'm not sure how it's possible
            if (! plasmoid.configuration.favoritesFlow == GridView.FlowLeftToRight) {
                var newx = gridView.contentX - movement;
                newx = Math.min(newx, gridView.contentWidth - width);
                newx = Math.max(newx, 0);
                gridView.contentX = newx;
            } else {
                // reimplement normal vertical scrolling
                var newy = gridView.contentY - movement;
                newy = Math.min(newy, gridView.contentHeight - height);
                newy = Math.max(newy, 0);
                gridView.contentY = newy;
            }
        }

        onPressed: {
            var mapped = gridView.mapToItem(gridView.contentItem, mouse.x, mouse.y);
            var item = gridView.itemAt(mapped.x, mapped.y);

            if (!item) {
                return;
            }

            if (mouse.buttons & Qt.RightButton) {
                if (item.hasActionList) {
                    mapped = gridView.contentItem.mapToItem(item, mapped.x, mapped.y);
                    gridView.currentItem.openActionMenu(mapped.x, mapped.y);
                }
            } else {
                pressed = item;
                pressX = mouse.x;
                pressY = mouse.y;
            }
        }

        onReleased: {
            var mapped = gridView.mapToItem(gridView.contentItem, mouse.x, mouse.y);
            var item = gridView.itemAt(mapped.x, mapped.y);

            if (item && pressed === item) {
                if (item.appView) {
                    view.state = "OutgoingLeft";
                } else {
                    item.activate();
                }

                gridView.currentIndex = -1;
            }

            pressed = null;
            pressX = -1;
            pressY = -1;
        }

        onPositionChanged: {
            var mapped = gridView.mapToItem(gridView.contentItem, mouse.x, mouse.y);
            var item = gridView.itemAt(mapped.x, mapped.y);

            if (item) {
                gridView.currentIndex = item.itemIndex;
            } else {
                gridView.currentIndex = -1;
            }

            if (pressed && pressX != -1 && pressed.url && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                kickoff.dragStartRow = item.itemIndex;
                kickoff.dragSource = item;
                dragHelper.startDrag(root, pressed.url, pressed.decoration);
                pressed = null;
                pressX = -1;
                pressY = -1;
            }
        }

        onContainsMouseChanged: {
            if (!containsMouse) {
                pressed = null;
                pressX = -1;
                pressY = -1;
            }
        }
    }
}
