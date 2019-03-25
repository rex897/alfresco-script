#!/bin/bash

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
export STATUS
export SERV_STAT=0

########################################
# Проверка запущен ли Tomcat
# Globals:
#   STATUS, ALF_HOME, RED, YELLOW, GREEN, NORMAL
# Arguments:
#   None
# Returns:
#   None
########################################
tomcatStop(){
STATUS=`${ALF_HOME}/alfresco.sh status`
if [[ "$STATUS" == *"tomcat already running"* ]]; then
  echo "${RED}Tomcat запущен${NORMAL}"
  echo "${YELLOW}Остановка Tomcat ${NORMAL}"
  ${ALF_HOME}/alfresco.sh stop tomcat
else 
  echo "${GREEN}tomcat не запущен${NORMAL}"
fi
}

########################################
# Удаление catalina.out
# Globals:
#   CATALINA_HOME
# Arguments:
#   None
# Returns:
#   None
########################################
rmCatalinaOut(){
if [ -f ${CATALINA_HOME}/logs/catalina.out ]; then
  rm -rf ${CATALINA_HOME}/logs/catalina.out
fi
}

########################################
# Ожидание запуска платформы
# Globals:
#   CATALINA_HOME, SERV_STAT
# Arguments:
#   None
# Returns:
#   None
########################################
waitServerStart(){
while [ $SERV_STAT -eq 0 ]; do
  sleep 10s
  SERV_STAT=`grep -c "INFO: Server startup in" ${CATALINA_HOME}/logs/catalina.out`
done
}

########################################
# Проверка установлен ли менеджер пакетов brew
########################################
if [[ $(command -v brew) == "" ]]; then
  echo "${YELLOW}Установка Homebrew ${NORMAL} ${NEWLINE}"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "${GREEN}Homebrew уже установлен${NORMAL}"
fi

########################################
# Проверка установлена ли утилита wget
########################################
echo "${GREEN}Утилита wget уже установлена ${NORMAL}${NEWLINE}$(brew list wget > /dev/null)" \
  || echo "${YELLOW}Установка wget для загрузки образа Alfresco ${NORMAL} ${NEWLINE}$(brew install wget)" 

########################################
# Проверка установлена ли утилита postgresql
########################################
echo "${GREEN}Утилита postgresql уже установлена ${NORMAL}${NEWLINE}$(brew list postgresql > /dev/null)" \
  || echo "${YELLOW}Установка postgresql ${NORMAL}${NEWLINE}$(brew install postgresql)"

########################################
# Проверка сущетсвования образа Alfresco
# на рбочей машине пользователя
########################################
if [ -f $ALFDWNLD ]; then
  echo "${GREEN}Образ Alfresco уже скачан ${NORMAL}"
else
  echo "${YELLOW}Загрузка образа Alfresco ${NORMAL} ${NEWLINE}"
  wget https://sourceforge.net/projects/alfresco/files/Alfresco%20201605%20Community/alfresco-community-installer-201605-osx-x64.dmg
fi

#########################################
# Монтирование диска
# Копирование образа
# Извлечение диска
#########################################
if [ -d $ALF_INST ]; then
  echo "${GREEN}Установочный файл Alfresco уже существует ${NORMAL}"
else
  echo "${YELLOW}Монтирование образа ${NORMAL}"
  hdiutil attach alfresco-community-installer-201605-osx-x64.dmg

  echo "${YELLOW}Копирование установочного файла в папку Application ${NORMAL}"
  cp -R /Volumes/Alfresco\ Community/alfresco-community-installer-201605-osx-x64.app /Applications

  echo "${YELLOW}Демонтирование образа ${NORMAL}"
  hdiutil detach /Volumes/Alfresco\ Community
fi

#########################################
# Если Alfresco установлена, то 
# переход к настройке бизнес-платформы.
# Иначе - установка.
#########################################
if [ -d $ALF_HOME ]; then
  echo "${GREEN}Alfesco уже установлена${NORMAL}"
else
  echo "${YELLOW}Запуск установочного файла Alfresco Community ${NORMAL}"
  echo "${RED}После завершения установки убрать все галочки ${NORMAL}"
  open /Applications/alfresco-community-installer-201605-osx-x64.app

  while pgrep -lf alfresco-community-installer > /dev/null; do
    sleep 1s
  done

  echo "${GREEN}Установка Alfresco Community завершилась ${NORMAL}${NEWLINE}"
fi

#########################################
# Если приложения Alfresco были запущены,
# необходимо остановить Tomcat
#########################################
tomcatStop

#########################################
# Запускаем postgresql, так как необходимо
# создать несколько БД.
#########################################
echo "${YELLOW}Настройка Бизнес-платформы ${NORMAL}"
rmCatalinaOut
${ALF_HOME}/alfresco.sh start postgresql
sleep 10s
echo "$(${ALF_HOME}/alfresco.sh status)"
SERV_STAT=0

#########################################
# Параметры кодировки файлов и языка
# пользователя.
#########################################
# TODO

#########################################
# Замена war-файлов «alfresco.war» и «share.war»
# на соответствующие файлы из дистрибутива
# бизнес-платформы.
#########################################
rm ${CATALINA_HOME}/webapps/alfresco.war
cp -R ./alfresco/alfresco.war ${CATALINA_HOME}/webapps
rm ${CATALINA_HOME}/webapps/share.war
cp -R ./alfresco/share.war ${CATALINA_HOME}/webapps

#########################################
# Удаление каталогов «alfresco» и «share»
#########################################
rm -rf ${CATALINA_HOME}/webapps/alfresco
rm -rf ${CATALINA_HOME}/webapps/share

#########################################
# Очистка моделей solr
#########################################
rm -rf ${ALF_DATA_HOME}/solr4/model

#########################################
# Бизнес-журнал
#########################################
echo "${YELLOW}Установка Бизнес-журнала ${NORMAL}"
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep db.name= | cut -f2 -d'='| cut -f1 -d' ' > name
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep db.password= | cut -f2 -d'='| cut -f1 -d' ' > pass
cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep alfresco.host= | cut -f2 -d'='| cut -f1 -d' ' > host
DB_PASS=$(< pass)
DB_NAME=$(< name)
ALF_HOST=$(< host)

export PGPASSWORD=${DB_PASS}
echo "${YELLOW}Создание БД bj${NORMAL}"
createdb bj --owner alfresco -U postgres
rm -rf name pass host

jar -xvf ./alfresco/businessjournal.war > /dev/null

sed -i '.bak' 's/datanucleus.password=.*/datanucleus.password='${DB_PASS}'/g' WEB-INF/classes/business-journal.properties
sed -i '.bak' 's/datanucleus.ConnectionURL=.*/datanucleus.ConnectionURL=jdbc:postgresql:\/\/'${ALF_HOST}':5432\/bj/g' WEB-INF/classes/business-journal.properties

jar -cvf businessjournal.war WEB-INF META-INF > /dev/null
cp -R ./alfresco/businessjournal.war ${CATALINA_HOME}/webapps
rm -rf WEB-INF META-INF *.bak
rm businessjournal.war

echo "${GREEN}Бизнес-журнал установлен ${NORMAL}"

#########################################
# Хранилище уведомлений
#########################################
echo "${YELLOW}Установка Хранилища уведомлений ${NORMAL}"

cp -R ./alfresco/notificationstore.war ${CATALINA_HOME}/webapps

echo "${YELLOW}Создание БД notifications${NORMAL}"
export PGPASSWORD=${DB_PASS}
createdb notifications --owner alfresco -U postgres

if [ `grep -c "notificationstore.datanucleus.dbms=" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 0 ]; then
  cat >> ${CATALINA_HOME}/shared/classes/alfresco-global.properties <<EOL
  ${NEWLINE}
  notificationstore.datanucleus.dbms=postgres
  notificationstore.datanucleus.ConnectionDriverName=org.postgresql.Driver
  notificationstore.datanucleus.ConnectionURL=jdbc:postgresql://localhost:5432/notifications
  notificationstore.datanucleus.ConnectionUserName=alfresco
  notificationstore.datanucleus.ConnectionPassword=admin
  notificationstore.datanucleus.generateSchema.database.mode=create
  notificationstore.brokerURL=tcp://127.0.0.1:61616
  notifications.store.protocol=http
  notifications.store.host=127.0.0.1
  notifications.store.port=8080
  notifications.store.name=notifications
EOL
fi

sed -i '.bak' 's/notificationstore.datanucleus.ConnectionUserName=.*/notificationstore.datanucleus.ConnectionUserName='${DB_NAME}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
sed -i '.bak' 's/notificationstore.datanucleus.ConnectionPassword=.*/notificationstore.datanucleus.ConnectionPassword='${DB_PASS}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
sed -i '.bak' 's/notificationstore.datanucleus.ConnectionURL=.*/notificationstore.datanucleus.ConnectionURL=jdbc:postgresql:\/\/'${ALF_HOST}':5432\/notifications/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties

rm -rf ${CATALINA_HOME}/shared/classes/alfresco-global.properties.bak

echo "${GREEN}Хранилище уведомлений установлено ${NORMAL}"

#########################################
# Печать штрихкодов
#########################################
# TODO взять варник модуля и попробовать поставить

#########################################
# В случае наличия ключа security.anyDenyDenies=false
# в файле
# CATALINA_HOME/shared/classes/alfresco-global.properties
# закомментировать или удалить строку целиком.
#########################################
if [ `grep -c "security.anyDenyDenies=false" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 1 ]; then
  sed -i '.bak' 's/security.anyDenyDenies=false.*//g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
fi
rm -rf ${CATALINA_HOME}/shared/classes/alfresco-global.properties.bak


#########################################
# Параметр для разворачивания справочников
#########################################
if [ `grep -c "lecm.dictionaries.bootstrapOnStart=true" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 0 ]; then
  cat >> ${CATALINA_HOME}/shared/classes/alfresco-global.properties <<EOL
  ${NEWLINE}
  lecm.dictionaries.bootstrapOnStart=true
EOL
fi

#########################################
# БД reporting
#########################################
echo "${YELLOW}Создание БД reporting${NORMAL}"

export PGPASSWORD=${DB_PASS}
createdb reporting --owner alfresco -U postgres

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


#########################################
# Лицензия
#########################################
cd /Users/ks/ДАТАТЕХ/alfresco-script
cp -R ./alfresco/lecmlicense ${CATALINA_HOME}/shared/classes

#########################################
# Какие-то настройки, без которых
# не работает БД
#########################################
if [ `grep -c "businessjournal.port=" ${CATALINA_HOME}/shared/classes/alfresco-global.properties` -eq 0 ]; then
  cat >> ${CATALINA_HOME}/shared/classes/alfresco-global.properties <<EOL
  ${NEWLINE}
  businessjournal.port=8080
  businessjournal.host=127.0.0.1
  datanucleus.ConnectionURL=jdbc:postgresql://localhost:5432/bj
  datanucleus.ConnectionUserName=postgres
  datanucleus.ConnectionPassword=1q2w3e4r5t
EOL
fi

sed -i '.bak' 's/datanucleus.ConnectionPassword=1q2w3e4r5t.*/datanucleus.ConnectionPassword='${DB_PASS}'/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties

#########################################
# Запуск Alfresco и необходимые настройки
#########################################
echo "${RED} Пункт \"Обязательная настройка Бизнес-платформы\" выполнить руками после запуска Alfresco${NORMAL}"

rmCatalinaOut
${ALF_HOME}/alfresco.sh restart
waitServerStart

tomcatStop

mv -v ${CATALINA_HOME}/webapps/alfresco.war ${CATALINA_HOME}/webapps/alf_alfresco.warrr
mv -v ${CATALINA_HOME}/webapps/share.war ${CATALINA_HOME}/webapps/sh_share.warrr

# sed -i '.bak' 's/lecm.dictionaries.bootstrapOnStart=true.*/lecm.dictionaries.bootstrapOnStart=false/g' ${CATALINA_HOME}/shared/classes/alfresco-global.properties
# rm -rf ${CATALINA_HOME}/shared/classes/alfresco-global.properties.bak

${ALF_HOME}/alfresco.sh start tomcat

cat ${CATALINA_HOME}/shared/classes/alfresco-global.properties | grep share.port= | cut -f2 -d'='| cut -f1 -d' ' > port
export SHARE_PORT=$(< port)
rm -rf port

open http://127.0.0.1:${SHARE_PORT}/share