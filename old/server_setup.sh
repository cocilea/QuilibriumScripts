#!/bin/bash -i

# Step 0: Welcome
echo "✨ Welcome! This script will prepare your server for the Quilibrium node installation. ✨"
echo "Made with 🔥 by LaMat"
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

# Define a function for displaying exit messages
exit_message() {
    echo "❌ Oops! There was an error during the script execution and the process stopped. No worries!"
    echo "🔄 You can try to run the script from scratch again."
    echo "🛠️ If you still receive an error, you may want to proceed manually, step by step instead of using the auto-installer."
}

# Step 1: Check sudo availability
if ! [ -x "$(command -v sudo)" ]; then
  echo "⚠️ Sudo is not installed! This script requires sudo to run. Exiting..."
  exit_message
  exit 1
fi

# Step 2: Update and Upgrade the Machine
echo "🔄 Updating the machine..."
echo "Processing... ⏳"
sleep 2  # Add a 2-second delay
sudo apt-get update
sudo apt-get upgrade -y

# Step 3: Install required packages
echo "🔧 Installing useful packages..."
sudo apt-get install git wget tmux tar -y || { echo "❌ Failed to install useful packages! Exiting..."; exit_message; exit 1; }

#!/bin/bash

# Step 4: Download and extract Go based on system architecture
if [[ $(go version) == *"go1.20.1"* || $(go version) == *"go1.20.2"* || $(go version) == *"go1.20.3"* || $(go version) == *"go1.20.4"* ]]; then
  echo "✅ Correct version of Go is already installed, moving on..."
else
  echo "⬇️ Installing the necessary version of Go..."

  # Get the system architecture
  ARCH=$(uname -m)
  
  # Determine the correct Go version to download based on architecture
  if [ "$ARCH" = "x86_64" ]; then
      GO_URL="https://go.dev/dl/go1.20.14.linux-amd64.tar.gz"
  elif [ "$ARCH" = "aarch64" ]; then
      GO_URL="https://go.dev/dl/go1.20.14.linux-arm64.tar.gz"
  elif [ "$ARCH" = "arm64" ]; then
      GO_URL="https://go.dev/dl/go1.20.14.linux-arm64.tar.gz"
  else
      echo "Unsupported architecture: $ARCH"
      exit 1
  fi

  # Download the selected Go version
  wget -4 $GO_URL || { echo "❌ Failed to download Go! Exiting..."; exit_message; exit 1; }
  
  # Extract the downloaded archive
  sudo tar -C /usr/local -xzf $(basename $GO_URL) || { echo "❌ Failed to extract Go! Exiting..."; exit_message; exit 1; }
  
  # Remove the downloaded archive
  sudo rm $(basename $GO_URL) || { echo "❌ Failed to remove downloaded archive! Exiting..."; exit_message; exit 1; }

fi


# Step 5: Set Go environment variables
echo "🌍 Setting Go environment variables..."

# Check if GOROOT is already set
if grep -q 'export GOROOT=/usr/local/go' ~/.bashrc; then
    echo "✅ GOROOT already set in ~/.bashrc."
else
    echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
    echo "✅ GOROOT set in ~/.bashrc."
fi

# Check if GOPATH is already set
if grep -q 'export GOPATH=$HOME/go' ~/.bashrc; then
    echo "✅ GOPATH already set in ~/.bashrc."
else
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo "✅ GOPATH set in ~/.bashrc."
fi

# Check if PATH is already set for Go
if grep -q 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' ~/.bashrc; then
    echo "✅ PATH already set in ~/.bashrc."
else
    echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.bashrc
    echo "✅ PATH set in ~/.bashrc."
fi

# Check if GO111MODULE is already set
if grep -q 'export GO111MODULE=on' ~/.bashrc; then
    echo "✅ GO111MODULE already set in ~/.bashrc."
else
    echo 'export GO111MODULE=on' >> ~/.bashrc
    echo "✅ GO111MODULE set in ~/.bashrc."
fi

# Check if GOPROXY is already set
if grep -q 'export GOPROXY=https://goproxy.cn,direct' ~/.bashrc; then
    echo "✅ GOPROXY already set in ~/.bashrc."
else
    echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.bashrc
    echo "✅ GOPROXY set in ~/.bashrc."
fi

# Step 5.1: Temporarily add variables - redundant but it help solving the command go not found error
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Source the ~/.bashrc to apply changes
source ~/.bashrc
sleep 2  # Add a 2-second delay

# Step 6: Adjust network buffer sizes
echo "🌐 Adjusting network buffer sizes..."
if grep -q "^net.core.rmem_max=600000000$" /etc/sysctl.conf; then
  echo "✅ net.core.rmem_max=600000000 found inside /etc/sysctl.conf, skipping..."
else
  echo -e "\n# Change made to increase buffer sizes for better network performance for ceremonyclient\nnet.core.rmem_max=600000000" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
if grep -q "^net.core.wmem_max=600000000$" /etc/sysctl.conf; then
  echo "✅ net.core.wmem_max=600000000 found inside /etc/sysctl.conf, skipping..."
else
  echo -e "\n# Change made to increase buffer sizes for better network performance for ceremonyclient\nnet.core.wmem_max=600000000" | sudo tee -a /etc/sysctl.conf > /dev/null
fi
sudo sysctl -p

# Step 7: Install gRPCurl
echo "📦 Installing gRPCurl..."
sleep 1  # Add a 1-second delay

# Try installing gRPCurl using go install
if go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest; then
    echo "✅ gRPCurl installed successfully via go install."
else
    echo "⚠️ Failed to install gRPCurl via go install. Trying apt-get..."
    # Try installing gRPCurl using apt-get
    if sudo apt-get install grpcurl -y; then
        echo "✅ gRPCurl installed successfully via apt-get."
    else
        echo "❌ Failed to install gRPCurl via apt-get! Moving on to the next step..."
        # Optionally, perform additional error handling here
    fi
fi


# Step 8: Install ufw and configure firewall
echo "🛡️ Installing ufw (Uncomplicated Firewall)..."
sudo apt-get update
sudo apt-get install ufw -y || { echo "❌ Failed to install ufw! Moving on to the next step..."; }

# Attempt to enable ufw
echo "🛡️ Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
    echo "y" | sudo ufw enable || { echo "❌ Failed to enable firewall! No worries, you can do it later manually."; }
else
    echo "⚠️ ufw (Uncomplicated Firewall) is not installed. Skipping firewall configuration."
fi

# Check if ufw is available and configured
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
    # Allow required ports
    for port in 22 8336 443; do
        if ! ufw_rule_exists "${port}"; then
            sudo ufw allow "${port}" || echo "⚠️ Error: Failed to allow port ${port}! You will need to allow port 8336 manually for the node to connect."
        fi
    done

    # Display firewall status
    sudo ufw status
    echo "✅ Firewall setup was successful."
else
    echo "⚠️ Failed to configure firewall or ufw is not installed. No worries, you can do it later manually. Moving on to the next step..."
fi

# Step 9: Creating some useful folders
echo "📂 Creating /root/backup/ folder..."
sudo mkdir -p /root/backup/
echo "✅ Done."

echo "📂 Creating /root/scripts/ folder..."
sudo mkdir -p /root/scripts/
echo "✅ Done."

echo "📂 Creating /root/scripts/log/ folder..."
sudo mkdir -p /root/scripts/log/
echo "✅ Done."

# Step 10: Prompt for reboot
echo "🎉 Server setup is finished!"
echo "🔄 Type 'sudo reboot' and press ENTER to reboot your server."
echo "🔗 Then follow the online guide for the next steps"
echo " to install your Quilibrium node as a service: https://iri.quest/quilibrium-node-guide" 
