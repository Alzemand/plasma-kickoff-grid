/*
 *  Copyright (C) 2019 cupnoodles <cupn8dles@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.5

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.kirigami 2.5 as Kirigami

Item {

    property alias cfg_menuHeight: menuHeightSpinBox.value
    property alias cfg_menuWidth: menuWidthSpinBox.value

    width: childrenRect.width
    height: childrenRect.height

    Kirigami.FormLayout {

        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            spacing: 6
            Kirigami.FormData.label: i18n("Menu width/height:")

            SpinBox {
                id: menuWidthSpinBox
                width: 200
                from: 10.0 // will be minimumValue in newer Qt
            }

            SpinBox {
                id: menuHeightSpinBox
                width: 200
                from: 20.0 // will be minimumValue in newer Qt
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }
    }
}
