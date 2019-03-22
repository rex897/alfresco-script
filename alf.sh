#!/bin/bash

# ------------------------------------------------------------------------------------------------------
# Переменные
# ------------------------------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------------------------------
# Проверка установлен ли менеджер пакетов brew
# ------------------------------------------------------------------------------------------------------

if [[ $(command -v brew) == "" ]];
    then
        echo "${YELLOW}Установка Homebrew ${NORMAL} ${NEWLINE}"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "${GREEN}Homebrew уже установлен${NORMAL}"
        #brew update
fi

# ------------------------------------------------------------------------------------------------------
# Проверка установлена ли утилита wget
# ------------------------------------------------------------------------------------------------------
echo "${GREEN}Утилита wget уже установлена ${NORMAL}${NEWLINE}$(brew list wget > /dev/null)" || echo "${YELLOW}Установка wget для загрузки образа Alfresco ${NORMAL} ${NEWLINE}$(brew install wget)" 

# ------------------------------------------------------------------------------------------------------
# Проверка установлена ли утилита postgresql (postgresql)
# ------------------------------------------------------------------------------------------------------
echo "${GREEN}Утилита postgresql уже установлена ${NORMAL}${NEWLINE}$(brew list postgresql > /dev/null)" || echo "${YELLOW}Установка postgresql ${NORMAL}${NEWLINE}$(brew install postgresql)"


echo "${GREEN}Текущая директория: $(pwd) ${NORMAL} ${NEWLINE}"

if [ -f $ALFDWNLD ];
    then
        echo "${GREEN}Образ Alfresco уже скачан ${NORMAL}"
    else
        echo "${YELLOW}Скачивание образа Alfresco ${NORMAL} ${NEWLINE}"
        wget https://sourceforge.net/projects/alfresco/files/Alfresco%20201605%20Community/alfresco-community-installer-201605-osx-x64.dmg
fi

# ------------------------------------------------------------------------------------------------------
# Монтирование диска, копирование образа, извлечение диска
# ------------------------------------------------------------------------------------------------------

if [ -d $ALF_INST ];
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

if [ -d $ALF_HOME ];
    then
        echo "${GREEN}Alfesco уже установлена${NORMAL}"
    else
        echo "${YELLOW}Запуск инсталлятора Alfresco Community ${NORMAL}"
        echo "${RED}После завершения установки убрать все галочки ${NORMAL}"

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

# ------------------------------------------------------------------------------------------------------
# Бизнес-платформа
# ------------------------------------------------------------------------------------------------------
if [ -f ${CATALINA_HOME}/logs/catalina.out ]; then
    rm -rf ${CATALINA_HOME}/logs/catalina.out
fi

${ALF_HOME}/alfresco.sh start

echo "$(${ALF_HOME}/alfresco.sh status)"
STATUS=`${ALF_HOME}/alfresco.sh status`

echo "${YELLOW}Ожидание запуска платформы ${NORMAL}"

SERV_STAT=`grep -c "INFO: Server startup in" ${CATALINA_HOME}/logs/catalina.out`
echo "$SERV_STAT"

while [ $SERV_STAT -eq 0 ]; do
    sleep 10s
    SERV_STAT=`grep -c "INFO: Server startup in" ${CATALINA_HOME}/logs/catalina.out`
done
SHARE_PORT=0
echo "${GREEN}Платформа запущена ${NORMAL}"

# ------------------------------------------------------------------------------------------------------
# Если сервис приложения Alfresco был запущен, необходимо остановить его
# ------------------------------------------------------------------------------------------------------

if [[ "$STATUS" == *"tomcat already running"* ]];
    then
        echo "${RED}Tomcat запущен${NORMAL}"
        echo "${YELLOW}Остановка Tomcat ${NORMAL}"
        ${ALF_HOME}/alfresco.sh stop tomcat
    else 
        echo "${GREEN}tomcat не запущен${NORMAL}"
fi

echo "${YELLOW}Установка Бизнес-платформы ${NORMAL}"
# ------------------------------------------------------------------------------------------------------
# Добавить к параметрам запуска сервиса обязательные параметры
# ------------------------------------------------------------------------------------------------------

# TODO

# ------------------------------------------------------------------------------------------------------
# Заменить war-файлы «alfresco.war» и «share.war» в каталоге «{catalina.home}/webapps» на соответствующие файлы из дистрибутива бизнес-платформы.
# ------------------------------------------------------------------------------------------------------

echo "${YELLOW}Замена war-файлов «alfresco.war» и «share.war» в каталоге «{catalina.home}/webapps» на соответствующие файлы из дистрибутива бизнес-платформы.${NORMAL}"

rm ${CATALINA_HOME}/webapps/alfresco.war
cp -R ./alfresco/alfresco.war ${CATALINA_HOME}/webapps

rm ${CATALINA_HOME}/webapps/share.war
cp -R ./alfresco/share.war ${CATALINA_HOME}/webapps

# ------------------------------------------------------------------------------------------------------
# Удалить каталоги «alfresco» и «share» из каталога «{catalina.home}/webapps».
# ------------------------------------------------------------------------------------------------------

echo "${YELLOW}Удаление каталогов «alfresco» и «share» из каталога «{catalina.home}/webapps».${NORMAL}"

rm -rf ${CATALINA_HOME}/webapps/alfresco
rm -rf ${CATALINA_HOME}/webapps/share

# ------------------------------------------------------------------------------------------------------
# Удалить содержимое каталога «<путь до папки инсталяции>/alf_data/solr4/model»
# ------------------------------------------------------------------------------------------------------

echo "${YELLOW}Удаление содержимого каталога «<путь до папки инсталяции>/alf_data/solr4/model.${NORMAL}"

rm -rf ${ALF_DATA_HOME}/solr4/model

# ------------------------------------------------------------------------------------------------------
# Установить сервис «Бизнес-журнал», выполнив действия, описанные в документе «Инструкция по установке Бизнес-журнала».
# ------------------------------------------------------------------------------------------------------

echo "${YELLOW}Установка Бизнес-журнала ${NORMAL}"

echo "${YELLOW}Копирование businessjournal.war в CATALINA_HOME/webapps${NORMAL}"
cp -R ./alfresco/businessjournal.war ${CATALINA_HOME}/webapps
cd ${CATALINA_HOME}/webapps
echo "${YELLOW}Распаковка businessjournal.war${NORMAL}"
jar -xvf businessjournal.war
rm businessjournal.war
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep db.name= | cut -f2 -d'='| cut -f1 -d' ' > name
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep db.password= | cut -f2 -d'='| cut -f1 -d' ' > pass
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep alfresco.host= | cut -f2 -d'='| cut -f1 -d' ' > host
export DB_PASS=$(< pass)
export DB_NAME=$(< name)
export ALF_HOST=$(< host)
export A_URL="jdbc:postgresql:\/\/${ALF_HOST}:5432\/${DB_NAME}"
echo "${YELLOW}Редактирование business-journal.properties${NORMAL}"
sed -i '.bak' 's/datanucleus.password=.*/datanucleus.password='${DB_PASS}'/g' WEB-INF/classes/business-journal.properties
sed -i '.bak' 's/datanucleus.ConnectionURL=.*/datanucleus.ConnectionURL='${A_URL}'/g' WEB-INF/classes/business-journal.properties
jar -cvf businessjournal.war WEB-INF META-INF
rm -rf WEB-INF META-INF name pass host *.bak
cd ${ALF_HOME}

echo "${GREEN}Бизнес-журнал установлен ${NORMAL}"

# ------------------------------------------------------------------------------------------------------
# Установить сервис «Хранилище уведомлений», выполнив действия, описанные в документе «Инструкция по установке хранилища уведомлений».
# ------------------------------------------------------------------------------------------------------

echo "${YELLOW}Установка Хранилища уведомлений ${NORMAL}"

echo "${YELLOW}Создание БД notifications${NORMAL}"
export PGPASSWORD=$DB_PASS
createdb notifications --locale 'ru_RU.UTF-8' --owner alfresco --template template0 -U postgres

echo "${YELLOW}Запись в alfresco-global.properties необходимых параметров${NORMAL}"

if [ `grep -c "notificationstore.datanucleus.dbms=postgres" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 0 ];
then
cat >> ${CATALINA_HOME}/shared/classes/alfresco-global.properties <<EOL
${NEWLINE}
notificationstore.datanucleus.dbms=postgres
notificationstore.datanucleus.ConnectionDriverName=org.postgresql.Driver
notificationstore.datanucleus.ConnectionURL=jdbc:postgresql://localhost:5432/notifications
notificationstore.datanucleus.ConnectionUserName=alfresco
notificationstore.datanucleus.ConnectionPassword=admin
notificationstore.datanucleus.generateSchema.database.mode=create
notificationstore.brokerURL=tcp://127.0.0.1:61616
EOL
fi

sed -i '.bak' 's/notificationstore.datanucleus.ConnectionUserName=.*/notificationstore.datanucleus.ConnectionUserName='${DB_NAME}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
sed -i '.bak' 's/notificationstore.datanucleus.ConnectionPassword=.*/notificationstore.datanucleus.ConnectionPassword='${DB_PASS}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
sed -i '.bak' 's/notificationstore.datanucleus.ConnectionURL=.*/notificationstore.datanucleus.ConnectionURL=jdbc:postgresql:\/\/'${ALF_HOST}':5432\/notifications/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties

rm -rf ${CATALINA_HOME}/shared/classes/alfresco-global.properties.bak

if [ -f ${CATALINA_HOME}/logs/catalina.out ]; then
rm -rf ${CATALINA_HOME}/logs/catalina.out
fi

${ALF_HOME}/alfresco.sh restart


while [ $SERV_STAT -eq 0 ]; do
    sleep 5s
    SERV_STAT=`grep -c "INFO: Server startup in" ${CATALINA_HOME}/logs/catalina.out`
done
SHARE_PORT=0
echo "${GREEN}Хранилище уведомлений установлено ${NORMAL}"

# ------------------------------------------------------------------------------------------------------
# Установить модуль удаленной печати, выполнив действия, описанные в документе «Печать штрихкодов. Проектное решение» (Шаг необязательный).
# ------------------------------------------------------------------------------------------------------

# TODO взять варник модуля и попробовать поставить

# ------------------------------------------------------------------------------------------------------
# Проверить в файле «<путь до папки инсталляции>\tomcat\shared\classes\alfresco-global.properties» наличие следующего ключа: security.anyDenyDenies=false. В случае наличия – закомментировать или удалить строку целиком.
# ------------------------------------------------------------------------------------------------------

if [ `grep -c "security.anyDenyDenies=false" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 1 ]; then
    sed -i '.bak' 's/security.anyDenyDenies=false.*//g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
fi
rm -rf ${CATALINA_HOME}/shared/classes/alfresco-global.properties.bak

# ------------------------------------------------------------------------------------------------------
# Добавить в файл «<путь до папки инсталляции>\tomcat\shared\classes\alfresco-global.properties» параметр для разворачивания справочников Системы (со значениями по умолчанию): lecm.dictionaries.bootstrapOnStart=true.
# ------------------------------------------------------------------------------------------------------

if [ `grep -c "lecm.dictionaries.bootstrapOnStart=true" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 0 ]; then
cat >> ${CATALINA_HOME}/shared/classes/alfresco-global.properties <<EOL
${NEWLINE}
lecm.dictionaries.bootstrapOnStart=true
EOL
fi

if [ -f ${CATALINA_HOME}/logs/catalina.out ]; then
rm -rf ${CATALINA_HOME}/logs/catalina.out
fi

${ALF_HOME}/alfresco.sh restart

while [ $SERV_STAT -eq 0 ]; do
    sleep 5s
    SERV_STAT=`grep -c "INFO: Server startup in" ${CATALINA_HOME}/logs/catalina.out`
done
SHARE_PORT=0
# Посте успешной загрузки сервера, для ускорения загрузки сервера, рекомендуется изменить данный параметр в значение false!

# ------------------------------------------------------------------------------------------------------
# Создать в СУБД под пользователем alfresco рядом с БД «alfresco» пустую БД «reporting». Добавить в файл «<путь до папки инсталляции>\tomcat\shared\classes\alfresco-global.properties» обязательные параметры модуля отчетности
# ------------------------------------------------------------------------------------------------------

export PGPASSWORD=$DB_PASS
createdb reporting --locale 'ru_RU.UTF-8' --owner alfresco --template template0 -U postgres

echo "${YELLOW}Запись в alfresco-global.properties необходимых параметров${NORMAL}"
if [ `grep -c "reporting.db.name=reporting" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 0 ]; then
cat >> ${CATALINA_HOME}/shared/classes/alfresco-global.properties <<EOL
${NEWLINE}
reporting.db.name=reporting
reporting.db.host=localhost
reporting.db.port=5432
reporting.db.username=alfresco
reporting.db.password=admin
reporting.db.driver=org.postgresql.Driver
reporting.db.url=jdbc:postgresql://localhost:5432/reporting
EOL
fi

sed -i '.bak' 's/reporting.db.host=.*/reporting.db.host='${ALF_HOST}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
sed -i '.bak' 's/reporting.db.password=.*/reporting.db.password='${DB_PASS}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
sed -i '.bak' 's/reporting.db.url=.*/reporting.db.url=jdbc:postgresql:\/\/'${ALF_HOST}':5432\/reporting/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
# ------------------------------------------------------------------------------------------------------
# Запустить Alfresco
# ------------------------------------------------------------------------------------------------------

#${ALF_HOME}/alfresco.sh restart

# ------------------------------------------------------------------------------------------------------
# Запуск должен завершиться автоматической остановкой. При этом необходимо проверить наличие файла «<путь до папки инсталляции>\activation».
# ------------------------------------------------------------------------------------------------------

# TODO хз надо или нет

# ------------------------------------------------------------------------------------------------------
# После успешного запуска сервера, во избежание процесса повторного разворачивания оригинальных war-файлов, настоятельно рекомендуется переименовать либо удалить файлы «alfresco.war» и «share.war» в каталоге «{catalina.home}/webapps». Перед удалением или переименованием файлов «alfresco.war» и «share.war» необходимо предварительно остановить сервер Tomcat.
# ------------------------------------------------------------------------------------------------------

if [[ "$STATUS" == *"tomcat already running"* ]];
    then
        echo "${RED}tomcat запущен"
        echo "${YELLOW}Остановка Tomcat ${NORMAL}"
        ${ALF_HOME}/alfresco.sh stop tomcat
    else 
        echo "${GREEN}tomcat не запущен"
fi

mv -v ${CATALINA_HOME}/webapps/alfresco.war ${CATALINA_HOME}/webapps/alf_alfresco.war
mv -v ${CATALINA_HOME}/webapps/share.war ${CATALINA_HOME}/webapps/sh_share.war
# ------------------------------------------------------------------------------------------------------
# Файл «activation» необходимо передать для генерации лицензии поставщику решения.
# ------------------------------------------------------------------------------------------------------

# TODO возможно этот шаг можно убрать

# ------------------------------------------------------------------------------------------------------
# Полученный файл с лицензией с именем «lecmlicense» необходимо поместить в каталог «{catalina.home}/shared/classes»
# ------------------------------------------------------------------------------------------------------

cd /Users/ks/ДАТАТЕХ/alfresco-script
cp -R ./alfresco/lecmlicense ${CATALINA_HOME}/shared/classes

# ------------------------------------------------------------------------------------------------------
# Запустить Alfresco. Результатом успешного запуска с установленной лицензией является успешный вход в систему.
# ------------------------------------------------------------------------------------------------------

if [ -f ${CATALINA_HOME}/logs/catalina.out ]; then
    rm -rf ${CATALINA_HOME}/logs/catalina.out
fi

${ALF_HOME}/alfresco.sh start

cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep share.port= | cut -f2 -d'='| cut -f1 -d' ' > port
export SHARE_PORT=$(< port)
rm -rf port

while [ $SERV_STAT -eq 0 ]; do
    sleep 5s
    SERV_STAT=`grep -c "INFO: Server startup in" ${CATALINA_HOME}/logs/catalina.out`
done

open http://127.0.0.1:${SHARE_PORT}/share


sed -i '.bak' 's/lecm.dictionaries.bootstrapOnStart=true.*/lecm.dictionaries.bootstrapOnStart=false/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
rm -rf ${CATALINA_HOME}/shared/classes/alfresco-global.properties.bak

echo "${RED} II.4. Обязательная настройка Бизнес-платформы выполнить руками ${NORMAL}"