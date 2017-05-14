FROM jboss/wildfly:latest

ADD customization /opt/jboss/wildfly/customization
ADD certificates /opt/jboss/wildfly/standalone/configuration/certificates

CMD ["/opt/jboss/wildfly/customization/install.sh"]
