#!/bin/bash

# Set the `MINECRAFT_SERVICE_NAME` environment variable to the name of the systemd service
export MINECRAFT_SERVICE_NAME="survival"
echo "Setting MINECRAFT_SERVICE_NAME to $MINECRAFT_SERVICE_NAME"

# Set the `MINECRAFT_JAR_PATH` environment variable to the path of the Minecraft server JAR file
export MINECRAFT_JAR_PATH="/opt/minecraft/$MINECRAFT_SERVICE_NAME"
echo "Setting MINECRAFT_JAR_PATH to $MINECRAFT_JAR_PATH"

# Get the latest version of Minecraft from Mojang's API
version=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
echo "The latest Minecraft server.jar version is $version"

# Define the latest server.jar file
export MINECRAFT_JAR_FILE="minecraft_server_$version.jar"

# Only perform update if a new version is detected
if [ -f "$MINECRAFT_JAR_PATH/$MINECRAFT_JAR_FILE" ]; then
        echo "Minecraft server is already using the latest version"
else
        echo "A new server.jar version has been released: $version"

        # Stop the Minecraft server
        echo "Stopping Minecraft server"
        systemctl stop minecraft@$MINECRAFT_SERVICE_NAME

        # Delete the existing Minecraft server JAR file
        echo "Delete existing minecraft server JAR file"
        find $MINECRAFT_JAR_PATH -name "*.jar" -type f -delete

        # Get the URL of the latest Minecraft server JAR file from Mojang's API
        jar_url=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r ".versions[] | select(.id==\"$version\") | .url" | xargs -I{} curl -s {} | jq -r ".downloads.server.url")
        echo "The corresponding URL is $jar_url"

        # Download the latest Minecraft server JAR file from Mojang
        echo "Downloading latest server JAR file: $MINECRAFT_JAR_FILE"
        wget $jar_url -O $MINECRAFT_JAR_PATH/$MINECRAFT_JAR_FILE

        # Copy the versioned server JAR to a generic name used by the service
        echo "Copying minecraft_server_$version.jar to server.jar"
        cp $MINECRAFT_JAR_PATH/$MINECRAFT_JAR_FILE $MINECRAFT_JAR_PATH/server.jar

        # Start the Minecraft server
        echo "Restarting the Minecraft server"
        systemctl start minecraft@$MINECRAFT_SERVICE_NAME
fi

# Check the status of the updated service
systemctl status minecraft@$MINECRAFT_SERVICE_NAME --no-pager

