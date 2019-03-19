#!/bin/bash

# ---------------------------------------------------
# Переменные
# ---------------------------------------------------
export ALF_HOME=/Applications/alfresco-community
export ALF_DATA_HOME=$ALF_HOME/alf_data
export CATALINA_HOME=$ALF_HOME/tomcat
export ALFDWNLD="alfresco-community-installer-201605-osx-x64.dmg" #  ${ALFDWNLD} имя загруженного образа Alfresco
export BOLD=`tput bold`       #  ${BOLD}      # жирный шрифт
export RED=`tput setaf 1`       #  ${RED}      # красный цвет знаков
export GREEN=`tput setaf 2`     #  ${GREEN}    # зелёный цвет знаков
export YELLOW=`tput setaf 3`     #  ${YELLOW}    # желтый цвет знаков
export NORMAL=`tput sgr0`      #  ${NORMAL}    # все атрибуты по умолчанию
export NEWLINE=$'\n'           # ${NEWLINE}
export ALF_INST=/Applications/alfresco-community-installer-201605-osx-x64.app
# ---------------------------------------------------
# Проверка установлен ли менеджер пакетов brew
# ---------------------------------------------------

if [[ $(command -v brew) == "" ]];
    then
        echo "${YELLOW}Установка Homebrew ${NORMAL} ${NEWLINE}"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "${GREEN}Homebrew уже установлен${NORMAL}"
        #brew update
fi

# ---------------------------------------------------
# Проверка установлена ли утилита wget
# ---------------------------------------------------
echo "${GREEN}Утилита wget уже установлена ${NORMAL}${NEWLINE}$(brew list wget > /dev/null)" || echo "${YELLOW}Установка wget для загрузки образа Alfresco ${NORMAL} ${NEWLINE}$(brew install wget)" 

# ---------------------------------------------------
# Проверка установлена ли утилита pv (prorgess bar)
# ---------------------------------------------------
echo "${GREEN}Утилита pv уже установлена ${NORMAL}${NEWLINE}$(brew list pv > /dev/null)" || echo "${YELLOW}Установка pv ${NORMAL}${NEWLINE}$(brew install pv)"

echo "${GREEN}Текущая директория: $(pwd) ${NORMAL} ${NEWLINE}"

if [ -f $ALFDWNLD ]
    then
        echo "${GREEN}Образ Alfresco уже скачан ${NORMAL}"
    else
        echo "${YELLOW}Скачивание образа Alfresco ${NORMAL} ${NEWLINE}"
        wget https://sourceforge.net/projects/alfresco/files/Alfresco%20201605%20Community/alfresco-community-installer-201605-osx-x64.dmg
fi

# ---------------------------------------------------
# Монтирование диска, копирование образа, извлечение диска
# ---------------------------------------------------

if [ -d $ALF_INST ]
    then
        echo "${GREEN}Инсталлер Alfresco уже есть в папке Application ${NORMAL}"
    else
        echo "${YELLOW}Монтирование образа ${NORMAL}"
        hdiutil attach alfresco-community-installer-201605-osx-x64.dmg
        echo "${GREEN}Образ смонтирован ${NORMAL}"

        echo "${YELLOW}Копирование инсталлятора в папку Application ${NORMAL}"
        cp -R /Volumes/Alfresco\ Community/alfresco-community-installer-201605-osx-x64.app /Applications

        echo "${YELLOW}Демонтирование образа ${NORMAL}"
        hdiutil detach /Volumes/Alfresco\ Community
fi

if [ -d $ALF_HOME ]
    then
        echo "${GREEN}Alfesco уже установлена"
    else
        echo "${YELLOW}Запуск инсталлятора Alfresco Community ${NORMAL}"
        echo "${GREEN}После завершения установки убрать все галочки ${NORMAL}"

        if [ -d $ALF_HOME ]
            then
                echo "${GREEN}Alfesco уже установлена"
            else
                open /Applications/alfresco-community-installer-201605-osx-x64.app
        fi

        while pgrep -lf alfresco-community-installer > /dev/null
        do
            sleep 1s
        done

        echo "${GREEN}Инсталлятор Alfresco Community завершил свою работу ${NORMAL}${NEWLINE}"
fi

# ---------------------------------------------------
# Бизнес-платформа
# ---------------------------------------------------
echo "${YELLOW}Установка Бизнес-платформы ${NORMAL}"

echo "$(${ALF_HOME}/alfresco.sh status)"
STATUS=`${ALF_HOME}/alfresco.sh status`

# Если сервис приложения Alfresco был запущен, необходимо остановить его

if [[ "$STATUS" == *"tomcat already running"* ]];
    then
        echo "${RED}tomcat запущен"
        echo "${YELLOW}Остановка Tomcat ${NORMAL}"
        ${ALF_HOME}/alfresco.sh stop tomcat
    else 
        echo "${GREEN}tomcat не запущен"
fi

# Добавить к параметрам запуска сервиса обязательные параметры




# Заменить war-файлы «alfresco.war» и «share.war» в каталоге «{catalina.home}/webapps» на соответствующие файлы из дистрибутива бизнес-платформы.

rm ${CATALINA_HOME}/webapps/alfresco.war
cp -R ./alfresco/alfresco.war ${CATALINA_HOME}/webapps

rm ${CATALINA_HOME}/webapps/share.war
cp -R ./alfresco/share.war ${CATALINA_HOME}/webapps

# Удалить каталоги «alfresco» и «share» из каталога «{catalina.home}/webapps».

rm -rf ${CATALINA_HOME}/webapps/alfresco
rm -rf ${CATALINA_HOME}/webapps/share

# Удалить содержимое каталога «<путь до папки инсталяции>/alf_data/solr4/model»

rm -rf ${ALF_DATA_HOME}/solr4/model

# Установить сервис «Бизнес-журнал», выполнив действия, описанные в документе «Инструкция по установке Бизнес-журнала».

cp -R ./alfresco/businessjournal.war ${CATALINA_HOME}/webapps
cd ${CATALINA_HOME}/webapps
jar -xvf businessjournal.war
rm businessjournal.war
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep db.name= | cut -f2 -d'='| cut -f1 -d' ' > name
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep db.password= | cut -f2 -d'='| cut -f1 -d' ' > pass
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep alfresco.host= | cut -f2 -d'='| cut -f1 -d' ' > host
export DB_PASS=$(< pass)
export DB_NAME=$(< name)
export ALF_HOST=$(< host)
export A_URL="jdbc:postgresql:\/\/${ALF_HOST}:5432\/${DB_NAME}"
sed -i '.bak' 's/datanucleus.password=.*/datanucleus.password='${DB_PASS}'/g' WEB-INF/classes/business-journal.properties
sed -i '.bak' 's/datanucleus.ConnectionURL=.*/datanucleus.ConnectionURL='${A_URL}'/g' WEB-INF/classes/business-journal.properties
jar -cvf businessjournal.war WEB-INF META-INF
rm -rf WEB-INF META-INF name pass host
# под вопросом удаление файла .bak

# Установить сервис «Хранилище уведомлений», выполнив действия, описанные в документе «Инструкция по установке хранилища уведомлений».


# Установить модуль удаленной печати, выполнив действия, описанные в документе «Печать штрихкодов. Проектное решение» (Шаг необязательный).



# Проверить в файле «<путь до папки инсталляции>\tomcat\shared\classes\alfresco- global.properties» наличие следующего ключа: security.anyDenyDenies=false. В случае наличия – закомментировать или удалить строку целиком.



# Добавить в файл «<путь до папки инсталляции>\tomcat\shared\classes\alfresco- global.properties» параметр для разворачивания справочников Системы (со значениями по умолчанию): lecm.dictionaries.bootstrapOnStart=true. Посте успешной загрузки сервера, для ускорения загрузки сервера, рекомендуется изменить данный параметр в значение false!



# Создать в СУБД под пользователем alfresco рядом с БД «alfresco» пустую БД «reporting». Добавить в файл «<путь до папки инсталляции>\tomcat\shared\classes\alfresco- global.properties» обязательные параметры модуля отчетности



# Запустить Alfresco

${ALF_HOME}/alfresco.sh start

# Запуск должен завершиться автоматической остановкой. При этом необходимо проверить наличие файла «<путь до папки инсталляции>\activation».



# После успешного запуска сервера, во избежание процесса повторного разворачивания оригинальных war-файлов, настоятельно рекомендуется переименовать либо удалить файлы «alfresco.war» и «share.war» в каталоге «{catalina.home}/webapps». Перед удалением или переименованием файлов «alfresco.war» и «share.war» необходимо предварительно остановить сервер Tomcat.



# Файл «activation» необходимо передать для генерации лицензии поставщику решения.


# Полученный файл с лицензией с именем «lecmlicense» необходимо поместить в каталог «{catalina.home}/shared/classes»

cp -R ./alfresco/lecmlicense ${CATALINA_HOME}/shared/classes

# Запустить Alfresco. Результатом успешного запуска с установленной лицензией является успешный вход в систему.

${ALF_HOME}/alfresco.sh start