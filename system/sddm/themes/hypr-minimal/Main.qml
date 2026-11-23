import QtQuick
import QtQuick.Effects
import SddmComponents 2.0

Item {
    id: root
    width: 1280
    height: 720

    // --- Tema Konfigürasyonu (theme.conf + theme.conf.user) ---
    function cfg(key, fallback) {
        if (typeof config !== "undefined" && config && config[key] !== undefined) {
            var val = String(config[key]).trim()
            if (val.length > 0)
                return val
        }
        return fallback
    }

    function withAlpha(col, a) {
        var c = Qt.color(col)
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    readonly property color colBg: cfg("bg", "#14130f")
    readonly property color colBgAlt: cfg("bg_alt", "#20201b")
    readonly property color colSurface: cfg("surface", "#2b2a25")
    readonly property color colFg: cfg("fg", "#e6e2db")
    readonly property color colFgMuted: cfg("fg_muted", "#cac7b7")
    readonly property color colAccent: cfg("accent", "#cdc98a")
    readonly property color colAccentAlt: cfg("accent_alt", "#cbc8a9")
    readonly property color colUrgent: cfg("urgent", "#ffb4ab")
    readonly property string uiFont: cfg("font", "Fira Sans")

    readonly property string rawBackground: cfg("background", "")
    readonly property url backgroundUrl: {
        if (rawBackground.length === 0)
            return ""
        if (rawBackground.indexOf("://") !== -1)
            return rawBackground
        if (rawBackground.charAt(0) === "/")
            return "file://" + rawBackground
        return Qt.resolvedUrl(rawBackground)
    }

    // 2560x1440 (ölçek 1.25 -> 1152 mantıksal yükseklik) Hyprlock oranıyla 1:1 uyum
    readonly property real s: Math.max(0.85, Math.min(1.35, root.height / 1152.0))
    readonly property bool isPrimary: (typeof primaryScreen === "undefined") || primaryScreen

    // --- Oturum & Kullanıcı Durumu ---
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string currentSessionName: "Hyprland"
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property string currentUser: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : ""
    property bool loggingIn: false
    property bool loginFailed: false
    property string statusText: ""
    property bool sessionMenuOpen: false
    property bool userMenuOpen: false

    // Türkçe saat ve tarih (sistem dilinden bağımsız tutarlı biçim)
    property date now: new Date()
    readonly property var trMonths: [
        "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ]
    readonly property var trDays: [
        "Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"
    ]

    function formattedTime() {
        var h = now.getHours()
        var m = now.getMinutes()
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }

    function formattedDate() {
        var d = now.getDate()
        var dd = (d < 10 ? "0" : "") + d
        return dd + " " + trMonths[now.getMonth()] + " " + now.getFullYear() + ", " + trDays[now.getDay()]
    }

    function closePopups() {
        sessionMenuOpen = false
        userMenuOpen = false
    }

    function doLogin() {
        if (loggingIn || currentUser.length === 0)
            return
        closePopups()
        loginFailed = false
        loggingIn = true
        statusText = "Oturum açılıyor..."
        sddm.login(currentUser, passwordInput.text, sessionIndex)
    }

    // --- Yeniden Kullanılabilir Tema Renkli SVG İkon ---
    component TintedIcon: Item {
        id: iconRoot
        property url source: ""
        property color color: root.colFg
        property real size: Math.round(18 * root.s)

        implicitWidth: size
        implicitHeight: size
        width: size
        height: size

        Image {
            id: rawImg
            anchors.fill: parent
            source: iconRoot.source
            sourceSize.width: Math.max(16, Math.round(iconRoot.size * 2))
            sourceSize.height: Math.max(16, Math.round(iconRoot.size * 2))
            smooth: true
            visible: false
        }

        MultiEffect {
            anchors.fill: rawImg
            source: rawImg
            colorization: 1.0
            colorizationColor: iconRoot.color
            visible: rawImg.status === Image.Ready
        }
    }

    // --- Saat Güncelleyici ---
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // --- SDDM Sinyalleri ---
    Connections {
        target: sddm

        function onLoginSucceeded() {
            root.loggingIn = false
            root.loginFailed = false
            root.statusText = ""
        }

        function onLoginFailed() {
            root.loggingIn = false
            root.loginFailed = true
            root.statusText = "Parola hatalı, tekrar deneyin"
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            shakeAnim.restart()
        }

        function onInformationMessage(message) {
            if (message && message.length > 0)
                root.statusText = message
        }
    }

    // =========================================================================
    // 1. ARKA PLAN — Bulanık Duvar Kağıdı + Koyu Perde (Hyprlock Estetiği)
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.colBgAlt }
            GradientStop { position: 1.0; color: root.colBg }
        }
    }

    Image {
        id: wallpaperImg
        anchors.fill: parent
        source: root.backgroundUrl
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: wallpaperImg
        source: wallpaperImg
        visible: wallpaperImg.status === Image.Ready
        blurEnabled: true
        blur: 0.62
        blurMax: 32
        autoPaddingEnabled: false
        brightness: -0.14
        saturation: 0.04
    }

    // Yumuşak karartma perdesi (hem açık hem koyu duvar kağıtlarında yüksek okunabilirlik)
    Rectangle {
        anchors.fill: parent
        color: root.withAlpha(root.colBg, wallpaperImg.status === Image.Ready ? 0.30 : 0.0)
    }

    // Hafif üst-alt vinyet
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.withAlpha(root.colBg, 0.36) }
            GradientStop { position: 0.35; color: "transparent" }
            GradientStop { position: 0.70; color: "transparent" }
            GradientStop { position: 1.0; color: root.withAlpha(root.colBg, 0.45) }
        }
    }

    // Boş alana tıklayınca açık menüleri kapat ve parola kutusuna odaklan
    MouseArea {
        anchors.fill: parent
        enabled: root.isPrimary
        onClicked: {
            root.closePopups()
            passwordInput.forceActiveFocus()
        }
    }

    // =========================================================================
    // 2. ANA İÇERİK — Yalnızca Birincil Ekranda
    // =========================================================================
    Item {
        id: uiLayer
        anchors.fill: parent
        visible: root.isPrimary
        opacity: 0

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 320
            easing.type: Easing.OutCubic
            running: true
        }

        // --- Merkez Blok: Saat, Tarih, Kullanıcı ve Parola Kutusu ---
        Column {
            id: centerBlock
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -Math.round(28 * root.s)
            spacing: 0

            // Saat (Hyprlock: 72px Bold)
            Text {
                id: clockLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.formattedTime()
                color: root.colFg
                font.family: root.uiFont
                font.pixelSize: Math.round(74 * root.s)
                font.weight: Font.Bold
                font.letterSpacing: -1.5 * root.s
                renderType: Text.NativeRendering
            }

            Item { width: 1; height: Math.round(6 * root.s) }

            // Türkçe Tarih (Hyprlock: 18px fg_muted)
            Text {
                id: dateLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.formattedDate()
                color: root.colFgMuted
                font.family: root.uiFont
                font.pixelSize: Math.round(18 * root.s)
                font.weight: Font.Normal
                renderType: Text.NativeRendering
            }

            Item { width: 1; height: Math.round(44 * root.s) }

            // Minimal Kullanıcı Rozeti (birden fazla kullanıcı varsa seçilebilir)
            Rectangle {
                id: userPill
                anchors.horizontalCenter: parent.horizontalCenter
                height: Math.round(32 * root.s)
                width: userPillRow.implicitWidth + Math.round(24 * root.s)
                radius: height / 2
                color: userPillMouse.containsMouse && userModel.count > 1
                    ? root.withAlpha(root.colSurface, 0.85)
                    : root.withAlpha(root.colBgAlt, 0.72)
                border.width: 1
                border.color: root.userMenuOpen
                    ? root.colAccent
                    : root.withAlpha(root.colSurface, 0.9)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: userPillRow
                    anchors.centerIn: parent
                    spacing: Math.round(7 * root.s)

                    TintedIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: Qt.resolvedUrl("icons/user.svg")
                        size: Math.round(14 * root.s)
                        color: root.colAccent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentUser
                        color: root.colFg
                        font.family: root.uiFont
                        font.pixelSize: Math.round(13.5 * root.s)
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }

                    TintedIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: typeof userModel !== "undefined" && userModel.count > 1
                        source: Qt.resolvedUrl("icons/chevron-down.svg")
                        size: Math.round(13 * root.s)
                        color: root.colFgMuted
                        rotation: root.userMenuOpen ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: userPillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (typeof userModel !== "undefined" && userModel.count > 1)
                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (typeof userModel !== "undefined" && userModel.count > 1) {
                            root.sessionMenuOpen = false
                            root.userMenuOpen = !root.userMenuOpen
                        }
                    }
                }
            }

            Item { width: 1; height: Math.round(14 * root.s) }

            // Parola Alanı (Hyprlock: 280-296 x 48, radius 12, 2px accent border)
            Item {
                id: passwordContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(296 * root.s)
                height: Math.round(48 * root.s)

                Rectangle {
                    id: passwordBox
                    width: parent.width
                    height: parent.height
                    x: 0
                    radius: Math.round(12 * root.s)
                    color: root.withAlpha(root.colBgAlt, 0.88)
                    border.width: 2
                    border.color: root.loginFailed
                        ? root.colUrgent
                        : (passwordInput.activeFocus ? root.colAccent : root.colSurface)

                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: passwordBox; property: "x"; to: -10; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordBox; property: "x"; to: 10; duration: 60; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordBox; property: "x"; to: -7; duration: 55; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordBox; property: "x"; to: 6; duration: 50; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: passwordBox; property: "x"; to: 0; duration: 45; easing.type: Easing.OutQuad }
                    }

                    // Placeholder ("Parola...")
                    Text {
                        anchors.centerIn: parent
                        text: "Parola..."
                        color: root.colFgMuted
                        font.family: root.uiFont
                        font.pixelSize: Math.round(14.5 * root.s)
                        opacity: passwordInput.text.length === 0 ? 0.72 : 0.0
                        renderType: Text.NativeRendering
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(40 * root.s)
                        anchors.rightMargin: Math.round(40 * root.s)
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: root.colFg
                        selectionColor: root.colAccent
                        selectedTextColor: root.colBg
                        font.family: root.uiFont
                        font.pixelSize: Math.round(12 * root.s)
                        font.letterSpacing: 3.5 * root.s
                        cursorVisible: false
                        clip: true
                        enabled: !root.loggingIn

                        onTextChanged: {
                            if (root.loginFailed && text.length > 0) {
                                root.loginFailed = false
                                root.statusText = ""
                            }
                        }

                        Keys.onReturnPressed: root.doLogin()
                        Keys.onEnterPressed: root.doLogin()
                        Keys.onEscapePressed: {
                            text = ""
                            root.loginFailed = false
                            root.statusText = ""
                            root.closePopups()
                        }
                    }

                    // Sağ tarafta sade giriş oku (parola yazıldığında belirir)
                    Rectangle {
                        id: submitBtn
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(6 * root.s)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(34 * root.s)
                        height: Math.round(34 * root.s)
                        radius: Math.round(8 * root.s)
                        color: submitMouse.containsMouse
                            ? root.withAlpha(root.colSurface, 0.9)
                            : "transparent"
                        opacity: (passwordInput.text.length > 0 && !root.loggingIn) ? 1.0 : 0.0
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        TintedIcon {
                            anchors.centerIn: parent
                            source: Qt.resolvedUrl("icons/arrow-right.svg")
                            size: Math.round(16 * root.s)
                            color: submitMouse.containsMouse ? root.colAccent : root.colFgMuted
                        }

                        MouseArea {
                            id: submitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.doLogin()
                        }
                    }
                }
            }

            Item { width: 1; height: Math.round(12 * root.s) }

            // Sabit Yükseklikli Durum / Hata / Caps Lock Satırı (ekranı zıplatmaz)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(320 * root.s)
                height: Math.round(24 * root.s)

                Row {
                    anchors.centerIn: parent
                    spacing: Math.round(6 * root.s)

                    TintedIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.statusText.length === 0 && typeof keyboard !== "undefined" && keyboard.capsLock
                        source: Qt.resolvedUrl("icons/capslock.svg")
                        size: Math.round(14 * root.s)
                        color: root.colAccentAlt
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (root.statusText.length > 0)
                                return root.statusText
                            if (typeof keyboard !== "undefined" && keyboard.capsLock)
                                return "Caps Lock açık"
                            return ""
                        }
                        color: root.loginFailed
                            ? root.colUrgent
                            : (root.loggingIn ? root.colAccent : root.colAccentAlt)
                        font.family: root.uiFont
                        font.pixelSize: Math.round(12.5 * root.s)
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        // --- Kullanıcı Seçim Menüsü (sadece >1 kullanıcıda açılır) ---
        Rectangle {
            id: userPopup
            visible: root.userMenuOpen
            anchors.horizontalCenter: centerBlock.horizontalCenter
            anchors.top: centerBlock.top
            anchors.topMargin: Math.round(176 * root.s)
            width: Math.round(220 * root.s)
            height: userPopupCol.implicitHeight + Math.round(12 * root.s)
            radius: Math.round(12 * root.s)
            color: root.withAlpha(root.colBg, 0.94)
            border.width: 1
            border.color: root.colAccent
            z: 50

            Column {
                id: userPopupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Math.round(6 * root.s)
                spacing: Math.round(3 * root.s)

                Repeater {
                    model: userModel
                    delegate: Rectangle {
                        required property int index
                        required property string name
                        width: userPopup.width - Math.round(12 * root.s)
                        height: Math.round(34 * root.s)
                        radius: Math.round(8 * root.s)
                        color: (name === root.currentUser || uItemMouse.containsMouse)
                            ? root.colSurface : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(12 * root.s)
                            anchors.right: parent.right
                            anchors.rightMargin: Math.round(12 * root.s)
                            elide: Text.ElideRight
                            text: name
                            color: name === root.currentUser ? root.colAccent : root.colFg
                            font.family: root.uiFont
                            font.pixelSize: Math.round(13 * root.s)
                            font.weight: name === root.currentUser ? Font.Medium : Font.Normal
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: uItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.userIndex = index
                                root.currentUser = name
                                root.userMenuOpen = false
                                passwordInput.forceActiveFocus()
                            }
                        }

                        Component.onCompleted: {
                            if (root.currentUser.length === 0 && index === 0)
                                root.currentUser = name
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 3. ALT SOL KAPSÜL — Oturum & Klavye Düzeni (Waybar Kapsül Estetiği)
        // =====================================================================
        Rectangle {
            id: leftPill
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Math.round(22 * root.s)
            height: Math.round(38 * root.s)
            width: leftPillRow.implicitWidth + Math.round(16 * root.s)
            radius: Math.round(12 * root.s)
            color: root.withAlpha(root.colBg, 0.84)
            border.width: 1
            border.color: root.withAlpha(root.colSurface, 0.9)

            Row {
                id: leftPillRow
                anchors.centerIn: parent
                spacing: Math.round(6 * root.s)

                // Oturum Seçici Butonu
                Rectangle {
                    id: sessionBtn
                    height: Math.round(28 * root.s)
                    width: sessionBtnRow.implicitWidth + Math.round(16 * root.s)
                    radius: Math.round(8 * root.s)
                    color: (sessionMouse.containsMouse || root.sessionMenuOpen)
                        ? root.withAlpha(root.colSurface, 0.72) : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        id: sessionBtnRow
                        anchors.centerIn: parent
                        spacing: Math.round(7 * root.s)

                        TintedIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qt.resolvedUrl("icons/session.svg")
                            size: Math.round(15 * root.s)
                            color: root.sessionMenuOpen ? root.colAccent : root.colFgMuted
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentSessionName
                            color: root.sessionMenuOpen ? root.colAccent : root.colFg
                            font.family: root.uiFont
                            font.pixelSize: Math.round(12.5 * root.s)
                            font.weight: Font.Medium
                            renderType: Text.NativeRendering
                        }

                        TintedIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Qt.resolvedUrl("icons/chevron-down.svg")
                            size: Math.round(12 * root.s)
                            color: root.colFgMuted
                            rotation: root.sessionMenuOpen ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.userMenuOpen = false
                            root.sessionMenuOpen = !root.sessionMenuOpen
                        }
                    }
                }

                // Ayırıcı Çizgi
                Rectangle {
                    visible: typeof keyboard !== "undefined" && keyboard.enabled && keyboard.layouts.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: Math.round(16 * root.s)
                    color: root.withAlpha(root.colSurface, 0.95)
                }

                // Klavye Düzeni (TR)
                Rectangle {
                    visible: typeof keyboard !== "undefined" && keyboard.enabled && keyboard.layouts.length > 0
                    height: Math.round(28 * root.s)
                    width: layoutText.implicitWidth + Math.round(14 * root.s)
                    radius: Math.round(8 * root.s)
                    color: (layoutMouse.containsMouse && keyboard.layouts.length > 1)
                        ? root.withAlpha(root.colSurface, 0.72) : "transparent"

                    Text {
                        id: layoutText
                        anchors.centerIn: parent
                        text: {
                            if (typeof keyboard !== "undefined" && keyboard.layouts && keyboard.layouts.length > 0) {
                                var cur = keyboard.layouts[keyboard.currentLayout]
                                if (cur && cur.shortName)
                                    return String(cur.shortName).toUpperCase()
                            }
                            return "TR"
                        }
                        color: root.colFgMuted
                        font.family: root.uiFont
                        font.pixelSize: Math.round(12 * root.s)
                        font.weight: Font.Medium
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: layoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (typeof keyboard !== "undefined" && keyboard.layouts.length > 1)
                            ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (typeof keyboard !== "undefined" && keyboard.layouts.length > 1) {
                                keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
                            }
                        }
                    }
                }
            }
        }

        // Oturum Açılır Menüsü (Rofi Estetiği — sol kapsülün hemen üstünde)
        Rectangle {
            id: sessionPopup
            visible: root.sessionMenuOpen
            anchors.left: leftPill.left
            anchors.bottom: leftPill.top
            anchors.bottomMargin: Math.round(8 * root.s)
            width: Math.round(240 * root.s)
            height: sessionPopupCol.implicitHeight + Math.round(12 * root.s)
            radius: Math.round(12 * root.s)
            color: root.withAlpha(root.colBg, 0.94)
            border.width: 1
            border.color: root.colAccent
            z: 50

            Column {
                id: sessionPopupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Math.round(6 * root.s)
                spacing: Math.round(3 * root.s)

                Repeater {
                    model: sessionModel
                    delegate: Rectangle {
                        required property int index
                        required property string name
                        width: sessionPopup.width - Math.round(12 * root.s)
                        height: Math.round(34 * root.s)
                        radius: Math.round(8 * root.s)
                        color: (index === root.sessionIndex || sItemMouse.containsMouse)
                            ? root.colSurface : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(12 * root.s)
                            anchors.right: parent.right
                            anchors.rightMargin: Math.round(12 * root.s)
                            elide: Text.ElideRight
                            text: name
                            color: index === root.sessionIndex ? root.colAccent : root.colFg
                            font.family: root.uiFont
                            font.pixelSize: Math.round(13 * root.s)
                            font.weight: index === root.sessionIndex ? Font.Medium : Font.Normal
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: sItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sessionIndex = index
                                root.currentSessionName = name
                                root.sessionMenuOpen = false
                                passwordInput.forceActiveFocus()
                            }
                        }

                        Component.onCompleted: {
                            if (index === root.sessionIndex)
                                root.currentSessionName = name
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 4. ALT SAĞ KAPSÜL — Güç Butonları (Uyku / Yeniden Başlat / Kapat)
        // =====================================================================
        component PowerActionButton: Rectangle {
            id: pBtn
            property url iconSource: ""
            property string tooltip: ""
            property color hoverColor: root.colAccent
            signal triggered()

            width: Math.round(32 * root.s)
            height: Math.round(28 * root.s)
            radius: Math.round(8 * root.s)
            color: pMouse.containsMouse ? root.withAlpha(root.colSurface, 0.72) : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }

            TintedIcon {
                anchors.centerIn: parent
                source: pBtn.iconSource
                size: Math.round(16 * root.s)
                color: pMouse.containsMouse ? pBtn.hoverColor : root.colFgMuted
            }

            // Sade hover etiketi
            Rectangle {
                visible: pMouse.containsMouse && pBtn.tooltip.length > 0
                anchors.bottom: parent.top
                anchors.bottomMargin: Math.round(12 * root.s)
                anchors.horizontalCenter: parent.horizontalCenter
                width: tipLabel.implicitWidth + Math.round(16 * root.s)
                height: Math.round(26 * root.s)
                radius: Math.round(8 * root.s)
                color: root.withAlpha(root.colBg, 0.94)
                border.width: 1
                border.color: root.withAlpha(root.colSurface, 0.95)

                Text {
                    id: tipLabel
                    anchors.centerIn: parent
                    text: pBtn.tooltip
                    color: root.colFg
                    font.family: root.uiFont
                    font.pixelSize: Math.round(11.5 * root.s)
                    renderType: Text.NativeRendering
                }
            }

            MouseArea {
                id: pMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pBtn.triggered()
            }
        }

        Rectangle {
            id: rightPill
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Math.round(22 * root.s)
            height: Math.round(38 * root.s)
            width: rightPillRow.implicitWidth + Math.round(14 * root.s)
            radius: Math.round(12 * root.s)
            color: root.withAlpha(root.colBg, 0.84)
            border.width: 1
            border.color: root.withAlpha(root.colSurface, 0.9)

            Row {
                id: rightPillRow
                anchors.centerIn: parent
                spacing: Math.round(4 * root.s)

                PowerActionButton {
                    visible: sddm.canSuspend
                    iconSource: Qt.resolvedUrl("icons/suspend.svg")
                    tooltip: "Uyku"
                    hoverColor: root.colAccent
                    onTriggered: sddm.suspend()
                }

                PowerActionButton {
                    visible: sddm.canReboot
                    iconSource: Qt.resolvedUrl("icons/reboot.svg")
                    tooltip: "Yeniden Başlat"
                    hoverColor: root.colAccent
                    onTriggered: sddm.reboot()
                }

                PowerActionButton {
                    visible: sddm.canPowerOff
                    iconSource: Qt.resolvedUrl("icons/power.svg")
                    tooltip: "Kapat"
                    hoverColor: root.colUrgent
                    onTriggered: sddm.powerOff()
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.isPrimary)
            passwordInput.forceActiveFocus()
    }
}
