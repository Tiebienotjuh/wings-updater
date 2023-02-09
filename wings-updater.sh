
#!/bin/bash
set -e

####################################################################################
# Copyright (c) 2023 Tiebienotjuh                                                  #
#                                                                                  #
# Permission is hereby granted, free of charge, to any person obtaining a copy     #
# of this software and associated documentation files (the "Software"), to deal    #
# in the Software without restriction, including without limitation the rights     #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell        #
# copies of the Software, and to permit persons to whom the Software is            #
# furnished to do so, subject to the following conditions:                         #
#                                                                                  #
# The above copyright notice and this permission notice shall be included in all   #
# copies or substantial portions of the Software.                                  #
#                                                                                  #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR       #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,         #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE      #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER           #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,    #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE    #
# SOFTWARE.                                                                        #
####################################################################################


get_latest_release() {
    curl --silent "https://api.github.com/repos/pterodactyl/wings/releases/latest" | jq -r .tag_name
}

update() {
    echo "Updating..."
    systemctl stop wings
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod u+x /usr/local/bin/wings
    systemctl start wings
    echo "Update done"
}

if [[ $1 == "check" ]]; then
    echo "Checking for updates..."
    current_release=$(sudo wings version | awk '{print $2}' | awk '{ print substr( $0, 2) }')
    latest_release=$(get_latest_release | awk '{ print substr( $0, 2) }')
    if [ $latest_release != $current_release ]; then
        echo "Update available!"
        echo "Current version: $current_release"
        echo "Latest version: $latest_release"
        # call update function
        update
    elif [ $latest_release = $current_release ]; then
        echo "No update available"
        echo "Current version: $current_release"
        echo "Latest version: $latest_release"
    else
        echo "Something went wrong"
    fi
elif [[ $1 == "update" ]]; then
    update
else
    # Check if wings are installed and configured
    if ! [ -x "$(command -v wings)" ]; then
        echo "Wings is not installed!"
        echo "Please install wings first"
        exit
    fi
    # Check if script is installed
    if [ -f /usr/local/bin/wings-updater.sh ]; then
        echo "Script is already installed!"
        echo "You can now run the script with 'wings-updater.sh check' or 'wings-updater.sh update'"
        echo "The script will check every day for updates and update if there is a new version available"
        exit
    fi

    echo "Installing script..."
    # Check if dependencies are installed
    if ! [ -x "$(command -v cron)" ]; then
        sudo apt-get update
        sudo apt-get install cron
    fi

    # get jq
    if ! [ -x "$(command -v jq)" ]; then
        sudo apt-get update
        sudo apt-get install jq
    fi
    
    # Create cronjob)
sudo tee /etc/cron.d/wings-updater <<EOF
0 0 * * * root /usr/local/bin/wings-updater.sh check
EOF

    # Copy script to /usr/local/bin
    sudo cp wings-updater.sh /usr/local/bin/wings-updater.sh
    sudo chmod +x /usr/local/bin/wings-updater.sh
    echo "Done!"
    echo "You can now run the script with 'wings-updater.sh check' or 'wings-updater.sh update'"
    echo "The script will check every day for updates and update if there is a new version available"

    # Run script once
    wings-updater.sh check
fi
