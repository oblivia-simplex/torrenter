FROM linuxserver/transmission:latest

RUN apk update && apk add openvpn htop iptables

ADD launch.sh /launch.sh

CMD [ "/launch.sh" ]
