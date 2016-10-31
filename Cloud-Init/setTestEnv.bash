# Add aditional tooling
#######################
# Inject sdkperf_java into test environment
sudo apt-get -y install openjdk-8-jre-headless
sudo apt-get -y install unzip
mkdir /home/ubuntu/test_env/Sdkperf
cd /home/ubuntu/test_env/Sdkperf
wget https://sftp.solace.com/download/SDKPERF_JAVA
wget https://sftp.solace.com/download/SDKPERF_MQTT
mv SDKPERF_JAVA ./sdkperf_java.zip
mv SDKPERF_MQTT ./sdkperf_mqtt.zip
unzip \*.zip
ln -s sdkperf-mqtt-* sdkperf-mqtt
ln -s sol-sdkperf-* sol-sdkperf
chmod 755 /home/ubuntu/test_env/Sdkperf/*/*sh

mkdir /home/ubuntu/test_env/MQTT_Example
ansible localhost -m git -a "repo=https://github.com/KenBarr/Solace_testing_in_AWS dest=/home/ubuntu/test_env/MQTT_Example"

# Get a copy of iperf that will run on VMR
sudo apt-get -y install iperf
cd /home/ubuntu
wget https://iperf.fr/download/fedora/iperf-2.0.5-13.fc21.x86_64.rpm:
