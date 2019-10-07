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

    property alias cfg_favoritesFlow: favoritesFlowComboBox.value
    property alias cfg_favoritesColumns: favoritesColumnsSpinBox.value
    property alias cfg_favoritesEnableSubtitles: favoritesEnableSubtitlesCheckbox.checked
    property alias cfg_favoritesLabelsPosition: favoritesLabelsPositionComboBox.value
    property alias cfg_favoritesIconSize: favoritesIconSizeSlider.iconSize

    width: childrenRect.width
    height: childrenRect.height

    Kirigami.FormLayout {

        anchors.left: parent.left
        anchors.right: parent.right

        ComboBox {
            id: favoritesFlowComboBox
            Kirigami.FormData.label: i18n("Flow:")

            property int value: model[currentIndex]["value"]

            currentIndex: flowToIndex(plasmoid.configuration.favoritesFlow)

            textRole: "label"
            model: [
                {
                    label: i18n("Rows"),
                    value: GridView.FlowLeftToRight,
                },
                {
                    label: i18n("Columns"),
                    value: GridView.FlowTopToBottom,
                }
            ]

            onCurrentIndexChanged: value = model[currentIndex]["value"]

            function flowToIndex(flow) {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]["value"] == flow) {
                        return i;
                    }
                }
                return 0;
            }
        }

        SpinBox {
            id: favoritesColumnsSpinBox
            Kirigami.FormData.label: i18n("Maximum columns on screen:")
            from: 1.0 // will be minimumValue in newer Qt
        }

        Slider {
            id: favoritesIconSizeSlider
            Kirigami.FormData.label: i18n("Icon size:")
            Layout.fillWidth: true
            from: 0
            to: 5
            stepSize: 1
            value: iconSizes.indexOf(plasmoid.configuration.favoritesIconSize)

            property int iconSize: iconSizes[value]
            property variant iconSizes : [
                units.iconSizes.small, units.iconSizes.smallMedium,
                units.iconSizes.medium, units.iconSizes.large,
                units.iconSizes.huge, units.iconSizes.enormous
            ]

            onValueChanged: iconSize = iconSizes[value]
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: i18n("Small")
                Layout.alignment: Qt.AlignLeft
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text: i18n("Large")
                Layout.alignment: Qt.AlignRight
            }
        }

        ComboBox {
            id: favoritesLabelsPositionComboBox
            Kirigami.FormData.label: i18n("Label position:")

            property string value: model[currentIndex]["value"]

            currentIndex: positionToIndex(plasmoid.configuration.favoritesLabelsPosition)

            textRole: "label"
            model: [
                {
                    label: i18n("Right"),
                    value: "right",
                },
                {
                    label: i18n("Bottom"),
                    value: "bottom",
                },
                {
                    label: i18n("Hidden"),
                    value: "hide",
                }
            ]

            onCurrentIndexChanged: value = model[currentIndex]["value"]

            function positionToIndex(position) {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]["value"] == position) {
                        return i;
                    }
                }
                return 0;
            }
        }

        CheckBox {
            id: favoritesEnableSubtitlesCheckbox
            enabled: (favoritesLabelsPositionComboBox.value != "hide")
            text: i18n("Display subtitles")
        }

        Item {
            Kirigami.FormData.isSection: true
        }
    }// Kirigami.FormLayout
}// Item
