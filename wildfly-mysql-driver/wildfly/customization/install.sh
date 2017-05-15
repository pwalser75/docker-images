#!/bin/bash

JBOSS_HOME=/opt/jboss/wildfly
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
JBOSS_MODE="standalone"
JBOSS_CONFIG="$JBOSS_MODE.xml"

JBOSS_CLI_USER=admin
JBOSS_CLI_PASSWORD=secret007


function cli {
    $JBOSS_CLI -u=$JBOSS_CLI_USER -p=$JBOSS_CLI_PASSWORD -c "$1"
}

function waitForServer() {
  until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do
    sleep 1
  done
}

# Create CLI user
echo "Creating JBoss CLI user"
$JBOSS_HOME/bin/add-user.sh $JBOSS_CLI_USER $JBOSS_CLI_PASSWORD

echo "> Starting WildFly server"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -c $JBOSS_CONFIG &
waitForServer

echo "> DB_URL: " $DB_URL
echo "> DB_USER: " $DB_USER
echo "> DB_PASSWORD: " $DB_PASSWORD
echo "> DATASOURCE_JNDI_NAME: " $DATASOURCE_JNDI_NAME
echo "> DEPLOYMENT_UNIT: " $DEPLOYMENT_UNIT

echo "Configuring SSL: security realm"
cli "/core-service=management/security-realm=\"ssl-only-realm\":add"
cli "/core-service=management/security-realm=\"ssl-only-realm\"/server-identity=\"ssl\":add(keystore-path=\"/opt/jboss/wildfly/standalone/configuration/certificates/server-keystore.jks\",keystore-password=\"keystore\",alias=\"wildfly-server\",key-password=\"secret\")"

echo "Configuring SSL: HTTPS listener"
cli "/subsystem=undertow/server=default-server/https-listener=https:remove"
cli "reload"
cli "/subsystem=undertow/server=default-server/https-listener=https:add(socket-binding=\"https\",security-realm=\"ssl-only-realm\",verify-client=\"REQUESTED\",enabled-protocols=\"TLSv1.1,TLSv1.2\",enabled-cipher-suites=\"TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA\",max-post-size=\"52428800\")"

echo "Add MySQL module"
cli "module add --name=com.mysql.driver --resources=$JBOSS_HOME/customization/mysql-connector-java-5.1.42-bin.jar --dependencies=javax.api,javax.transaction.api"
echo "Add MySQL driver"
cli "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql.driver,driver-class-name=com.mysql.jdbc.Driver, driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)"

echo "Add MySQL datasource"
cli "xa-data-source add --name=testDb --driver-name=mysql --jndi-name=$DATASOURCE_JNDI_NAME --user-name=$DB_USER --password=$DB_PASSWORD --xa-datasource-properties=[{URL=$DB_URL}]"

echo "Deploy application"
cli "deploy $JBOSS_HOME/customization/$DEPLOYMENT_UNIT"

echo "> Shuting down WildFly"
cli ":shutdown"

echo "> Restarting WildFly server"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -c $JBOSS_CONFIG


