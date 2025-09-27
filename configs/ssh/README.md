# Certifiate Authority Authentication
## How it works
1. First, you will need to set up a certificate authority (CA). This is a server that will sign your certificates. The same ssh-keygen command can be used to create a CA.

2. The private key of the CA is used to sign user and host (SSH server) certificates.

3. Once the keys are signed, they are distributed to users and hosts, respectively.

4.  The public key of the CA is copied to the SSH server, which is used to verify the user's certificate.

## Do it yourself
1. Create a CA

```bash
ssh-keygen -t rsa -b 4096 -f ssh_host_ca -C ssh_host_ca

Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in ssh_host_ca
Your public key has been saved in ssh_host_ca.pub
The key fingerprint is:
SHA256:slohp1o9UUFReRJoKPjwAZ4jLrEDkNLpD3Jm0MrsH2g ssh_host_ca
The key's randomart image is:
+---[RSA 4096]----+
|.+.+   o++oo     |
|=.*.o . o.o .    |
|B+++ o ..  o     |
|=**.o  .         |
|=*.o. = S        |
|.E ..= =         |
|. . + =          |
|   + o .         |
|  . .            |
+----[SHA256]-----+
```

2. The host_ca file is the host CA's private key and should be protected. Don't give it out to anyone, don't copy it anywhere and make sure that as few people have access to it as possible. Ideally, it should live on a machine which doesn't allow direct access, and all certificates should be issued by an automated process.

## Issue user certificates to authenticate users to hosts
1. Make a key for packer to use during the build runtime.

```bash
ssh-keygen -f packer-build-key -b 4096 -t rsa
```

2. Sign the key with the CA. I'm going to make this one valid for 1 day (```-V +1d```) and for the username packer (```-n packer```). The -I flag is the identity of the user so I can use it to identify the user in the ssh config.

```bash
ssh-keygen -s ssh_host_ca -I packer@buildserver -n packer -V +1d packer-build-key.pub

Signed user key packer-build-key-cert.pub: id "packer@buildserver" serial 0 for packer valid from 2025-03-08T11:23:00 to 2025-03-09T12:24:08
```

3. You can use the ```-L``` flag to list the certificate details.

```bash
ssh-keygen -L -f packer-build-key-cert.pub

packer-build-key-cert.pub:
        Type: ssh-rsa-cert-v01@openssh.com user certificate
        Public key: RSA-CERT SHA256:fmEFJJxkAYa389ckXgnbk2tmT45ow2gRk8a3Mv69ik0
        Signing CA: RSA SHA256:slohp1o9UUFReRJoKPjwAZ4jLrEDkNLpD3Jm0MrsH2g (using rsa-sha2-512)
        Key ID: "packer@buildserver"
        Serial: 0
        Valid: from 2025-03-08T11:23:00 to 2025-03-09T12:24:08
        Principals:
                packer
        Critical Options: (none)
        Extensions:
                permit-X11-forwarding
                permit-agent-forwarding
                permit-port-forwarding
                permit-pty
                permit-user-rc
```

## Modify the SSH config on the server side to accept certificates signed by the CA
1. Copy the CA public key to the server's ```/etc/ssh/``` directory.

```bash
 cp ~rossethridge/ssh/ssh_host_ca.pub /etc/ssh/
```

2. Edit the ```/etc/ssh/sshd_config``` file and allow that pub key to be trusted.

```bash
# vi /etc/ssh/sshd_config
TrustedUserCAKeys /etc/ssh/ssh_host_ca.pub
```

3. Restart the SSH daemon.
```bash
systemclt daemon-reload
systemctl restart sshd
```

## Test it out
1. Use the ```-i``` flag to specify the private key to use and lets try to connect to the server as ```packer``` using the certificate.

```bash
ssh -i ./packer-build-key  packer@ross-notebook

Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.6.36.6-microsoft-standard-WSL2+ x86_64)

Last login: Sat Mar  8 11:56:13 2025 from 127.0.0.1
packer@ross-notebook:~$
```

VIOLA!
