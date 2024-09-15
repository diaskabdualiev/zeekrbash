#!/bin/bash

# Цветовые коды
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# URLs для скачивания APK-файлов
RUSTORE_URL="https://www.rustore.ru/download"
ZEEAPPSTORE_URL="https://store.anyapp.tech/zeeappstore/apps/store/storeUpdate.apk"

# Имена файлов APK
RUSTORE_APK="rustore.apk"
ZEEAPPSTORE_APK="zeeappstore.apk"

# Функция для получения времени и часового пояса с устройства
function show_time_and_timezone() {
    echo -e "${BLUE}Время телефона:${RESET} $(adb shell date | tr -d '\r')"
    echo -e "${BLUE}Часовой пояс телефона:${RESET} $(adb shell getprop persist.sys.timezone | tr -d '\r')"
}

# Функция для вывода текущей клавиатуры по умолчанию
function show_default_keyboard() {
    default_keyboard=$(adb shell settings get secure default_input_method | tr -d '\r')
    echo -e "${YELLOW}Текущая клавиатура по умолчанию:${RESET} $default_keyboard"
}

# Функция для получения версии приложения
function get_app_version() {
    package_name=$1
    version=$(adb shell dumpsys package $package_name | grep versionName | awk -F= '{print $2}' | tr -d '\r')
    echo $version
}

# Функция для получения актуальной версии из API
function get_actual_version_from_api() {
    api_url="https://store.anyapp.tech/zeeappstore/config.json"
    actual_version=$(curl -s $api_url | grep '"version"' | awk -F'"' '{print $4}')
    echo $actual_version
}

# Функция для проверки установленных магазинов приложений и их разрешений
function check_app_stores() {
    echo -e "${YELLOW}Проверка магазинов приложений и их разрешений:${RESET}"

    # Проверка, установлен ли com.anyapp.zee.store
    echo -n "Магазин com.anyapp.zee.store: "
    is_installed=$(adb shell pm list packages | grep "com.anyapp.zee.store")
    if [[ -z "$is_installed" ]]; then
        echo -e "${RED}не установлен${RESET}"
    else
        echo -e "${GREEN}установлен${RESET}"

        # Получение версии приложения
        version=$(get_app_version "com.anyapp.zee.store")
        echo -e "${YELLOW}Версия приложения:${RESET} $version"

        # Получение актуальной версии из API
        actual_version=$(get_actual_version_from_api)
        echo -e "${YELLOW}Актуальная версия из API:${RESET} $actual_version"

        # Проверка разрешений для установки приложений
        permission_status=$(adb shell appops get com.anyapp.zee.store REQUEST_INSTALL_PACKAGES | grep "allow")
        if [[ -z "$permission_status" ]]; then
            echo -e "${RED}Разрешение на установку приложений не выдано${RESET}"
        else
            echo -e "${GREEN}Разрешение на установку приложений выдано${RESET}"
        fi
    fi

    # Проверка, установлен ли ru.vk.store
    echo -n "Магазин ru.vk.store: "
    is_installed=$(adb shell pm list packages | grep "ru.vk.store")
    if [[ -z "$is_installed" ]]; then
        echo -e "${RED}не установлен${RESET}"
    else
        echo -e "${GREEN}установлен${RESET}"

        # Получение версии приложения
        version=$(get_app_version "ru.vk.store")
        echo -e "${YELLOW}Версия приложения:${RESET} $version"

        # Проверка разрешений для установки приложений
        permission_status=$(adb shell appops get ru.vk.store REQUEST_INSTALL_PACKAGES | grep "allow")
        if [[ -z "$permission_status" ]]; then
            echo -e "${RED}Разрешение на установку приложений не выдано${RESET}"
        else
            echo -e "${GREEN}Разрешение на установку приложений выдано${RESET}"
        fi
    fi
}

# Функция для проверки установки приложения backkey и его разрешений
function check_backkey() {
    echo -e "${YELLOW}Проверка приложения Backkey и его разрешений:${RESET}"

    # Проверка, установлен ли backkey
    is_installed=$(adb shell pm list packages | grep "com.appspot.app58us.backkey")
    if [[ -z "$is_installed" ]]; then
        echo -e "${RED}Приложение Backkey не установлено${RESET}"
    else
        echo -e "${GREEN}Приложение Backkey установлено${RESET}"

        # Проверка разрешения SYSTEM_ALERT_WINDOW
        permission_status=$(adb shell dumpsys package com.appspot.app58us.backkey | grep "android.permission.SYSTEM_ALERT_WINDOW: granted=true")
        if [[ -z "$permission_status" ]]; then
            echo -e "${RED}Разрешение SYSTEM_ALERT_WINDOW не выдано${RESET}"
        else
            echo -e "${GREEN}Разрешение SYSTEM_ALERT_WINDOW выдано${RESET}"
        fi

        # Проверка настройки enabled_accessibility_services
        accessibility_status=$(adb shell settings get secure enabled_accessibility_services | grep "com.appspot.app58us.backkey/com.appspot.app58us.backkey.BackkeyService")
        if [[ -z "$accessibility_status" ]]; then
            echo -e "${RED}Служба BackkeyService не включена в настройках доступности${RESET}"
        else
            echo -e "${GREEN}Служба BackkeyService включена в настройках доступности${RESET}"
        fi
    fi
}

# Функция для скачивания APK-файлов магазинов приложений
function download_app_stores() {
    echo -e "${YELLOW}Скачивание APK-файлов магазинов приложений...${RESET}"

    # Скачивание ZeeAppStore
    if [[ ! -f "$ZEEAPPSTORE_APK" ]]; then
        echo -e "${BLUE}Скачивание ZeeAppStore...${RESET}"
        wget -O "$ZEEAPPSTORE_APK" "$ZEEAPPSTORE_URL"
    else
        echo -e "${GREEN}ZeeAppStore APK уже скачан.${RESET}"
    fi

    # Скачивание RuStore
    if [[ ! -f "$RUSTORE_APK" ]]; then
        echo -e "${BLUE}Скачивание RuStore...${RESET}"
        wget -O "$RUSTORE_APK" "$RUSTORE_URL"
    else
        echo -e "${GREEN}RuStore APK уже скачан.${RESET}"
    fi
}

# Функция для установки магазинов приложений на устройство
function install_app_stores() {
    echo -e "${YELLOW}Установка магазинов приложений на устройство...${RESET}"

    # Установка ZeeAppStore
    if [[ -f "$ZEEAPPSTORE_APK" ]]; then
        echo -e "${BLUE}Установка ZeeAppStore...${RESET}"
        adb install -r "$ZEEAPPSTORE_APK"
    else
        echo -e "${RED}Файл $ZEEAPPSTORE_APK не найден. Сначала скачайте APK.${RESET}"
    fi

    # Установка RuStore
    if [[ -f "$RUSTORE_APK" ]]; then
        echo -e "${BLUE}Установка RuStore...${RESET}"
        adb install -r "$RUSTORE_APK"
    else
        echo -e "${RED}Файл $RUSTORE_APK не найден. Сначала скачайте APK.${RESET}"
    fi
}

# Функция для выдачи разрешений магазинам приложений
function grant_permissions() {
    echo -e "${YELLOW}Выдача разрешений магазинам приложений...${RESET}"

    # Выдача разрешения для com.anyapp.zee.store
    is_installed=$(adb shell pm list packages | grep "com.anyapp.zee.store")
    if [[ ! -z "$is_installed" ]]; then
        echo -e "${BLUE}Выдача разрешения com.anyapp.zee.store...${RESET}"
        adb shell appops set --user 0 com.anyapp.zee.store REQUEST_INSTALL_PACKAGES allow
    else
        echo -e "${RED}com.anyapp.zee.store не установлен.${RESET}"
    fi

    # Выдача разрешения для ru.vk.store
    is_installed=$(adb shell pm list packages | grep "ru.vk.store")
    if [[ ! -z "$is_installed" ]]; then
        echo -e "${BLUE}Выдача разрешения ru.vk.store...${RESET}"
        adb shell appops set --user 0 ru.vk.store REQUEST_INSTALL_PACKAGES allow
    else
        echo -e "${RED}ru.vk.store не установлен.${RESET}"
    fi
}

# Функция для выдачи разрешений приложению Backkey
function grant_backkey_permissions() {
    echo -e "${YELLOW}Выдача разрешений приложению Backkey...${RESET}"

    # Проверка, установлен ли backkey
    is_installed=$(adb shell pm list packages | grep "com.appspot.app58us.backkey")
    if [[ -z "$is_installed" ]]; then
        echo -e "${RED}Приложение Backkey не установлено.${RESET}"
    else
        # Выдача разрешения SYSTEM_ALERT_WINDOW
        echo -e "${BLUE}Выдача разрешения SYSTEM_ALERT_WINDOW...${RESET}"
        adb shell pm grant com.appspot.app58us.backkey android.permission.SYSTEM_ALERT_WINDOW

        # Включение службы доступности BackkeyService
        echo -e "${BLUE}Включение службы доступности BackkeyService...${RESET}"
        adb shell settings put secure enabled_accessibility_services com.appspot.app58us.backkey/com.appspot.app58us.backkey.BackkeyService
        adb shell settings put secure accessibility_enabled 1

        echo -e "${GREEN}Разрешения выданы.${RESET}"
    fi
}

# Функция для отображения состояния важных настроек
function show_verifier_settings() {
    echo -e "${YELLOW}Проверка настроек Verifier:${RESET}"

    # Проверка, установлено ли приложение com.ecarx.xsfinstallverifier
    is_installed=$(adb shell pm list packages | grep "com.ecarx.xsfinstallverifier")
    if [[ -z "$is_installed" ]]; then
        echo -e "${RED}Приложение com.ecarx.xsfinstallverifier не установлено${RESET}"
    else
        # Проверка, отключено ли оно
        verifier_status=$(adb shell pm list packages -d | grep "com.ecarx.xsfinstallverifier")
        if [[ -z "$verifier_status" ]]; then
            echo -e "${GREEN}Приложение com.ecarx.xsfinstallverifier включено${RESET}"
        else
            echo -e "${RED}Приложение com.ecarx.xsfinstallverifier отключено${RESET}"
        fi
    fi

    # Проверка статуса глобальных настроек
    package_verifier_enable=$(adb shell settings get global package_verifier_enable | tr -d '\r')
    if [ "$package_verifier_enable" == "1" ]; then
        echo -e "${GREEN}Проверка пакетов включена (package_verifier_enable):${RESET} $package_verifier_enable"
    else
        echo -e "${RED}Проверка пакетов отключена (package_verifier_enable):${RESET} $package_verifier_enable"
    fi

    verifier_verify_adb_installs=$(adb shell settings get global verifier_verify_adb_installs | tr -d '\r')
    if [ "$verifier_verify_adb_installs" == "1" ]; then
        echo -e "${GREEN}Проверка установок через ADB включена (verifier_verify_adb_installs):${RESET} $verifier_verify_adb_installs"
    else
        echo -e "${RED}Проверка установок через ADB отключена (verifier_verify_adb_installs):${RESET} $verifier_verify_adb_installs"
    fi
}

# Функция для включения/отключения приложения com.ecarx.xsfinstallverifier
function toggle_ecarx_verifier() {
    is_installed=$(adb shell pm list packages | grep "com.ecarx.xsfinstallverifier")
    if [[ -z "$is_installed" ]]; then
        echo -e "${RED}Приложение com.ecarx.xsfinstallverifier не установлено.${RESET}"
        return
    fi

    verifier_status=$(adb shell pm list packages -d | grep "com.ecarx.xsfinstallverifier")
    if [[ -z "$verifier_status" ]]; then
        # Приложение включено, предлагаем отключить
        echo -e "${YELLOW}Приложение com.ecarx.xsfinstallverifier включено. Отключить? (y/n):${RESET}"
        read -p "" choice
        if [[ "$choice" == "y" ]]; then
            adb shell pm disable-user --user 0 com.ecarx.xsfinstallverifier
            echo -e "${GREEN}Приложение отключено.${RESET}"
        else
            echo -e "${YELLOW}Действие отменено.${RESET}"
        fi
    else
        # Приложение отключено, предлагаем включить
        echo -e "${YELLOW}Приложение com.ecarx.xsfinstallverifier отключено. Включить? (y/n):${RESET}"
        read -p "" choice
        if [[ "$choice" == "y" ]]; then
            adb shell pm enable com.ecarx.xsfinstallverifier
            echo -e "${GREEN}Приложение включено.${RESET}"
        else
            echo -e "${YELLOW}Действие отменено.${RESET}"
        fi
    fi
}

# Функция для включения/отключения настроек проверки пакетов
function toggle_package_verifier_settings() {
    # Проверка текущих настроек
    package_verifier_enable=$(adb shell settings get global package_verifier_enable | tr -d '\r')
    verifier_verify_adb_installs=$(adb shell settings get global verifier_verify_adb_installs | tr -d '\r')

    # Предлагаем переключить настройки
    echo -e "${YELLOW}Текущие настройки проверки пакетов:${RESET}"
    echo -e "package_verifier_enable: $package_verifier_enable"
    echo -e "verifier_verify_adb_installs: $verifier_verify_adb_installs"

    echo -e "${YELLOW}Вы хотите переключить состояние этих настроек? (y/n):${RESET}"
    read -p "" choice
    if [[ "$choice" == "y" ]]; then
        # Переключаем package_verifier_enable
        if [ "$package_verifier_enable" == "1" ]; then
            adb shell settings put global package_verifier_enable 0
            echo -e "${GREEN}package_verifier_enable отключен.${RESET}"
        else
            adb shell settings put global package_verifier_enable 1
            echo -e "${GREEN}package_verifier_enable включен.${RESET}"
        fi

        # Переключаем verifier_verify_adb_installs
        if [ "$verifier_verify_adb_installs" == "1" ]; then
            adb shell settings put global verifier_verify_adb_installs 0
            echo -e "${GREEN}verifier_verify_adb_installs отключен.${RESET}"
        else
            adb shell settings put global verifier_verify_adb_installs 1
            echo -e "${GREEN}verifier_verify_adb_installs включен.${RESET}"
        fi
    else
        echo -e "${YELLOW}Действие отменено.${RESET}"
    fi
}

# Функция для установки приложений из папки "apps"
function install_apps_from_folder() {
    echo -e "${YELLOW}Установка приложений из папки 'apps'...${RESET}"

    if [[ -d "apps" ]]; then
        for apk in apps/*.apk; do
            if [[ -f "$apk" ]]; then
                echo -e "${BLUE}Установка ${apk}...${RESET}"
                adb install -r "$apk"
            else
                echo -e "${RED}Нет APK-файлов в папке 'apps'.${RESET}"
            fi
        done
    else
        echo -e "${RED}Папка 'apps' не найдена.${RESET}"
    fi
}

# Функция для вывода списка доступных клавиатур с выделением текущей
function list_keyboards() {
    default_keyboard=$(adb shell settings get secure default_input_method | tr -d '\r')

    echo -e "${YELLOW}Доступные клавиатуры:${RESET}"
    keyboards=$(adb shell ime list -a | grep 'mId=' | awk '{print $1}' | cut -d '=' -f2)
    IFS=$'\n' read -r -d '' -a keyboard_array <<< "$keyboards"

    for i in "${!keyboard_array[@]}"; do
        if [ "${keyboard_array[$i]}" == "$default_keyboard" ]; then
            echo -e "$((i + 1))) ${GREEN}${keyboard_array[$i]} (Текущая)${RESET}"
        else
            echo -e "$((i + 1))) ${keyboard_array[$i]}"
        fi
    done
}

# Функция для смены клавиатуры
function change_keyboard() {
    list_keyboards
    echo -e "${YELLOW}Введите номер клавиатуры, которую хотите установить по умолчанию:${RESET}"
    read keyboard_choice

    # Проверяем, что введено число
    if [[ "$keyboard_choice" =~ ^[0-9]+$ ]] && [ "$keyboard_choice" -le "${#keyboard_array[@]}" ]; then
        selected_keyboard="${keyboard_array[$((keyboard_choice - 1))]}"
        default_keyboard=$(adb shell settings get secure default_input_method | tr -d '\r')

        # Отключаем текущую клавиатуру
        echo -e "${YELLOW}Отключение текущей клавиатуры:${RESET} $default_keyboard"
        adb shell ime disable "$default_keyboard"

        # Активируем выбранную клавиатуру
        echo -e "${YELLOW}Включение выбранной клавиатуры:${RESET} $selected_keyboard"
        adb shell ime enable "$selected_keyboard"

        # Устанавливаем выбранную клавиатуру по умолчанию
        adb shell ime set "$selected_keyboard"

        echo -e "${GREEN}Клавиатура успешно изменена на $selected_keyboard${RESET}"
    else
        echo -e "${RED}Неверный выбор. Попробуйте снова.${RESET}"
    fi
}

# Главное меню
function main_menu() {
    while true; do
        # Отображаем начальную информацию каждый раз при возврате в меню
        echo -e "\n${BLUE}=== Начальная информация ===${RESET}"
        show_time_and_timezone
        show_default_keyboard
        show_verifier_settings
        check_app_stores
        check_backkey

        echo -e "${BLUE}\nВыберите опцию:${RESET}"
        echo "1) Смена клавиатуры"
        echo "2) Скачивание магазинов приложений"
        echo "3) Установка магазинов приложений"
        echo "4) Выдача разрешений магазинам приложений"
        echo "5) Включить/отключить com.ecarx.xsfinstallverifier"
        echo "6) Включить/отключить настройки проверки пакетов"
        echo "7) Установка приложений из папки 'apps'"
        echo "8) Выдача разрешений приложению Backkey"
        echo "9) Выход"

        read -p "Ваш выбор: " choice

        case $choice in
            1)
                change_keyboard
                ;;
            2)
                download_app_stores
                ;;
            3)
                install_app_stores
                ;;
            4)
                grant_permissions
                ;;
            5)
                toggle_ecarx_verifier
                ;;
            6)
                toggle_package_verifier_settings
                ;;
            7)
                install_apps_from_folder
                ;;
            8)
                grant_backkey_permissions
                ;;
            9)
                echo -e "${BLUE}Выход.${RESET}"
                break
                ;;
            *)
                echo -e "${RED}Неверный ввод. Попробуйте снова.${RESET}"
                ;;
        esac
    done
}

# Основная программа
main_menu
