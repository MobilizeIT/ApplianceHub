# How to create a self-signed certificate using OpenSSL?
1. Setup CA for signing

  openssl genrsa -out ca-key.pem 2048
  
  openssl req -new -x509 -sha256 -nodes -days 730 -key ca-key.pem -out ca-cert.pem
2. Generate a server private key and CSR
  
  openssl req -newkey rsa:2048 -days 730 -nodes -keyout server-key.pem -out server-req.pem

3. CA sign CSR and get server cert
  
  openssl x509 -req -in server-req.pem -days 730 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem


##Checking server security using client
  
  openssl s_client -host <hostname> -port <port>

##Checking cert
  
  openssl x509 -in <certificate_to_check.pem> -noout -text

