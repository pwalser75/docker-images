#!/bin/bash

JBOSS_HOME=/opt/jboss/wildfly
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
JBOSS_MODE="standalone"
JBOSS_CONFIG="$JBOSS_MODE.xml"

function wait_for_server() {
  until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do
    sleep 1
  done
}

echo "> Starting WildFly server"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -c $JBOSS_CONFIG &

echo "> Waiting for the server to boot"
wait_for_server

echo "> Executing the commands"
echo "> MYSQL_HOST (explicit): " $MYSQL_HOST
echo "> MYSQL_PORT (explicit): " $MYSQL_PORT
echo "> MYSQL (docker host): " $DB_PORT_3306_TCP_ADDR
echo "> MYSQL (docker port): " $DB_PORT_3306_TCP_PORT
echo "> MYSQL (k8s host): " $MYSQL_SERVICE_SERVICE_HOST
echo "> MYSQL (k8s port): " $MYSQL_SERVICE_SERVICE_PORT
echo "> MYSQL_URI (docker with networking): " $MYSQL_URI

$JBOSS_CLI -c << EOF
batch

#set CONNECTION_URL=jdbc:mysql://$MYSQL_SERVICE_SERVICE_HOST:$MYSQL_SERVICE_SERVICE_PORT/sample
set CONNECTION_URL=jdbc:mysql://$MYSQL_URI/sample
echo "Connection URL: " $CONNECTION_URL

# Add MySQL module
# module add --name=com.mysql.driver --resources=$JBOSS_HOME/installation/mysql-connector-java-5.1.42-bin.jar --dependencies=javax.api,javax.transaction.api

# Add MySQL driver
# /subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql.driver,driver-class-name=com.mysql.jdbc.Driver, driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)

# Add MySQL datasource
xa-data-source add --name=testDb --driver-name=mysql --jndi-name=java:/jdbc/testDb --user-name=test --password=secret --xa-datasource-properties=[{URL=jdbc:mysql://mysql-link:3306/test_schema}]

# Deploy application
deploy $JBOSS_HOME/installation/webapp-project.war

# Execute the batch
run-batch
EOF

echo "=> Shutting down WildFly"
if [ "$JBOSS_MODE" = "standalone" ]; then
  $JBOSS_CLI -c ":shutdown"
else
  $JBOSS_CLI -c "/host=*:shutdown"
fi

echo "=> Restarting WildFly"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -c $JBOSS_CONFIG
