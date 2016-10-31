echo "`date` Place private key on test hosts"
echo "-----BEGIN RSA PRIVATE KEY-----" > /home/ubuntu/${AWS_KEY_NAME}.pem
echo ${AWS_KEY_VALUE} | tr " " "\n" >> /home/ubuntu/${AWS_KEY_NAME}.pem
echo "-----END RSA PRIVATE KEY-----" >> /home/ubuntu/${AWS_KEY_NAME}.pem
chmod 600  /home/ubuntu/${AWS_KEY_NAME}.pem
