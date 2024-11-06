# Step 1: Use an official openjdk image as the base image
FROM openjdk:21-jdk-slim

# Step 2: Install necessary dependencies
RUN apt-get update && apt-get install -y wget unzip curl nginx jq && rm -rf /var/lib/apt/lists/*

# Step 3: Download and install Jena and Jena Fuseki
ENV JENA_VERSION=5.2.0
ENV JENA_HOME=/opt/apache-jena
ENV JENA_FUSEKI_HOME=/opt/apache-jena-fuseki

RUN wget https://dlcdn.apache.org/jena/binaries/apache-jena-fuseki-${JENA_VERSION}.zip \
    && unzip apache-jena-fuseki-${JENA_VERSION}.zip \
    && mv apache-jena-fuseki-${JENA_VERSION} $JENA_FUSEKI_HOME \
    && rm apache-jena-fuseki-${JENA_VERSION}.zip

RUN wget https://dlcdn.apache.org/jena/binaries/apache-jena-${JENA_VERSION}.zip \
    && unzip apache-jena-${JENA_VERSION}.zip \
    && mv apache-jena-${JENA_VERSION} $JENA_HOME \
    && rm apache-jena-${JENA_VERSION}.zip

# Step 4: Copy the Fuseki configuration file
COPY fuseki/fuseki-config.ttl $JENA_FUSEKI_HOME/configuration/fuseki-config.ttl
RUN sed -i "s?{{JENA_FUSEKI_HOME}}?$JENA_FUSEKI_HOME?g" $JENA_FUSEKI_HOME/configuration/fuseki-config.ttl

# Step 5: Modify webapp/index.html to insert Google Analytics code
RUN sed -i '/<\/head>/i <!-- Google tag (gtag.js) -->\n<script async src="https://www.googletagmanager.com/gtag/js?id=G-7C29LFPZT2"></script>\n<script>\n  window.dataLayer = window.dataLayer || [];\n  function gtag(){dataLayer.push(arguments);}\n  gtag('"'"'js'"'"', new Date());\n  gtag('"'"'config'"'"', '"'"'G-7C29LFPZT2'"'"');\n</script>' $JENA_FUSEKI_HOME/webapp/index.html

# Step 6: Configure Nginx to serve the dist directory
RUN rm /etc/nginx/sites-enabled/default
COPY visualization/dist /usr/share/nginx/html
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Step 7: Copy the TDB2 database file and create the database
RUN mkdir -p $JENA_FUSEKI_HOME/rdf-data \
    && LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/purdue-hcss/secure-chain-knowledge-graph/releases/latest | jq -r '.assets[] | select(.name=="secure-chain.ttl") | .browser_download_url') \
    && wget $LATEST_RELEASE_URL -O $JENA_FUSEKI_HOME/rdf-data/secure-chain.ttl
# Create the TDB2 database from the RDF file
RUN $JENA_HOME/bin/tdb2.tdbloader --loc=$JENA_FUSEKI_HOME/tdb2/secure-chain $JENA_FUSEKI_HOME/rdf-data/secure-chain.ttl

# Step 8: Expose default Fuseki port and Nginx port
EXPOSE 3030 80

# Step 9: Create an entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Step 10: Set the entrypoint to start Fuseki and Nginx
ENTRYPOINT ["/entrypoint.sh"]
