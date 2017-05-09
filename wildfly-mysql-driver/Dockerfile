FROM jboss/wildfly
COPY files/mysql-connector-java-5.1.42-bin.jar /root
COPY files/webapp-project.war /root

RUN /opt/jboss/wildfly/bin/add-user.sh admin secret-007 --silent

RUN /opt/jboss/wildfly/bin/jboss-cli.sh -c "module add --name=com.mysql --resources=/root/mysql-connector-java-5.1.42-bin.jar --dependencies=javax.api,javax.transaction.api"

RUN /opt/jboss/wildfly/bin/jboss-cli.sh -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql.driver,driver-class-name=com.mysql.jdbc.Driver, driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)"

RUN /opt/jboss/wildfly/bin/jboss-cli.sh -c "xa-data-source add --name=testDb --driver-name=mysql --jndi-name=java:/jdbc/testDb --user-name=test --password=secret --xa-datasource-properties=[{URL=jdbc:mysql://mysql-link:3306/test_schema}]"

RUN /opt/jboss/wildfly/bin/jboss-cli.sh -c "deploy /root/webapp-project.war webapp-project.war"
