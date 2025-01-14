#! /bin/sh
# System startup script for local packet filters on a bastion server
# in a DMZ (NOT for an actual firewall)
# Created by Esteban Herrera.

# Useful iptables commands to debugging rule's time:

# Shows the rules' table:
#iptables -L

# Shows the rules's table, giving a consecutive number to each rule: 
#iptables -L -n --line

# Eliminate one rule by its consecutive number (e.g.: "1"):
#iptables -D INPUT 1

# Flush active rules and custom tables (for me including the tables of the program fail2ban.
# Stops the firewall. The system will need some rules.
# Notice: iptables -F = iptables --flush
#iptables --flush
#iptables --delete-chain

# Secuence to a wide open firewall, used, for example, after a wrong setup: 
#iptables --flush
#iptables -P INPUT ACCEPT
#iptables -P FORWARD ACCEPT
#iptables -P OUTPUT ACCEPT

# Querying iptables status
#iptables --line-numbers -v --list


# Modules required by the specified module.
# (The other way to up modules at startup is to add them to /etc/modules. With 'modprobe'
# every module is up with the correspondent modules as dependencies. To list modules use 'lsmod'.
modprobe ip_tables
modprobe ip_conntrack_ftp

# Flush active rules and custom tables
# Next commands are specifically applied to do not touch the fail2ban custom chains,
# See 'man i[ptables' for details:
iptables --flush -t nat
# iptables --flush -t filter
# iptables --delete-chain


# Set default-deny policies for all three default chains
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Give free reign to the loopback interfaces, i.e. local processes may connect
# to other processes' listening-ports.
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Do some rudimentary anti-IP-spoofing drops. The rule of thumb is "drop
#  any source IP address which is impossible" (per RFC 1918)
#
# NOTE: If you use RFC 1918 address-space, comment out or edit the appropriate 
#  lines below!
#
iptables -A INPUT -s 255.0.0.0/8 -j LOG --log-prefix "Spoofed source IP"
iptables -A INPUT -s 255.0.0.0/8 -j DROP
iptables -A INPUT -s 0.0.0.0/8 -j LOG --log-prefix "Spoofed source IP"
iptables -A INPUT -s 0.0.0.0/8 -j DROP
iptables -A INPUT -s 127.0.0.0/8 -j LOG --log-prefix "Spoofed source IP"
iptables -A INPUT -s 127.0.0.0/8 -j DROP
# The local IP of my server is 192.168.1.6, so activating next 2 lines the mail
# server (squirrelmail Front end) does not connect to localhost (IMAP)!
#iptables -A INPUT -s 192.168.0.0/16 -j LOG --log-prefix "Spoofed source IP"
#iptables -A INPUT -s 192.168.0.0/16 -j DROP 
iptables -A INPUT -s 172.16.0.0/12 -j LOG --log-prefix "Spoofed source IP"
iptables -A INPUT -s 172.16.0.0/12 -j DROP
iptables -A INPUT -s 10.0.0.0/8 -j LOG --log-prefix " Spoofed source IP"
iptables -A INPUT -s 10.0.0.0/8 -j DROP

# Commands to help debugging software installation:
# To list open ports (services are named under /etc/services):
#netstat -plunt
#netstat -plunt | grep 123
# To scan from remote host open ports (services listening for new requests only, no client
# ports):
#nmap -O remote_host
# Scan specific ports (Client ports like 123 will appear as closed):
#nmap -p 1186 x1
#nmap -p 123 x1
# Port tool http://www.canyouseeme.org/
# Check network, i.e. DNS, Gateway, proxy
# Check router DMZ and configuration

# In this section we will add the list of IP CONFLICTIVE addresses that attacked
# us for example with DDOS or Brute Force, problems not resolved with something
# like apache mod evasive.

# Useful commands at combat time versus attackers:
#netstat -nr [Kernel ip routing table].
#netstat .inet -aln [See all the active sockets of ports].
#netstat -tap [Verify  connection, for example, open ports of the server].
#netstat -i [Displays the configured	interfaces].
#netstat -ia [Displays all the interfaces].
#netstat -ta [Displays the active TCP connections, with the ports in LISTEN state].
# When we are  being attacked, an excellent way to discover the requests to 
# the 80 port by IP is (as root):
#netstat -plan|grep :80 | awk {'print $5'}|cut -d: -f 1|sort|uniq -c|sort -n
# Other 'netstat' command will tell what are IPs with established connections:
#netstat -plan|grep :80 |  grep ESTABLISHED | awk {'print $5'}|cut -d: -f 1|sort|uniq -c|sort -n
# Both commands will help us to recognize what IP (or IPs) is (or are) exceeding the max permitted
# requests' quantity (when the attack is on port ":80").
# The next step is to filter the address is giving problems, for example using the 'APF' program
# 'sh> /usr/local/sbin/apf -d <IP conflictive>'.
#traceroute -n www.google.com [Verifies routes and connectivity].   
#traceroute -i 208.67.222.222 [Verifies routes but and connectivity but using ICMP (Internet
# Control Message Protocol) messages].
#mtr .-psize 1024 208.67.222.222	[Verifies. An option to traceroute command but with more 
# displays. This example is using the DNS for cronos, the DNS assigning 
#arp -e [Verify the arp tables].
# Install the nmap sniffer with 'apt-get update', then type 'apt-get install nmap'.
#nmap {-s scanningKind} {-p portsRange} -F options objective [nmap scanner syntax].
#nmap -sT -F -P0 -O woofgang.dogpeople.org		[Probing iptables and a strong system].
#nmap -sTUR -F -P0 -O woofgang.dogpeople.org 		[A more detailed port scanning].
#nmap -sP 192.168.0.0/24 [Sniff a network].
# If can't identify intruder install snort, a network intrusion prevention and detection system
# (IDS/IPS). For more info visit: http://www.snort.org.
# More here...

# Consider next line to insert, in real time, the attacker IP address, in the command line
# Then, if needed you will add the address ro thte blacklist below. THis will help
# when we can't stop the active connections in the firewall because of the natures of the rules
# where all is DROPPED by default. The '-I' part of the command means "insert", and the 
# the number '1' tells the new rule line will be inserted before the rule number '1'.
# Before any insertion verify the rule numbers to the INPUT chain, and be carefull:

#iptables -I INPUT 1 -s 192.168.1.4 -j LOG --log-prefix "Potential RT DoS src IP"
#iptables -I INPUT 1 -s 192.168.1.4 -j DROP


# --------------------------

# In this way we are not going to accept incoming requests (inputs) from MyBlackList addresses:
# In the next example, a local client with a local ip.

#iptables -A INPUT -s 192.168.1.4 -j LOG --log-prefix "Potential DoS source IP"
#iptables -A INPUT -s 192.168.1.4 -j DROP



# --------------------------

## The following will NOT interfere with local inter-process traffic, whose
#   packets have the source IP of the local loopback interface, e.g. 127.0.0.1
# (The source is our IP [$IP_LOCAL] , so it is false.

iptables -A INPUT -s 201.201.101.162 -j LOG --log-prefix "Spoofed source myIP"
iptables -A INPUT -s 201.201.101.162 -j DROP

# Tell netfilter that all TCP sessions do indeed begin with SYN
#   (There may be some RFC-non-compliant application somewhere which 
#    begins its transactions otherwise, but if so I've never heard of it)

iptables -A INPUT -p tcp ! --syn -m state --state NEW -j LOG --log-prefix "Stealth scan attempt?"
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

# Finally, the meat of our packet-filtering policy:

# INBOUND POLICY
#   (Applies to packets entering our network interface from the network, 
#   and addressed to this host)

# Useful List of ports:
# <<< Ports to open list (the complete list in on the file /etc/services): >>>
# Search services with: 'sh> cat /etc/services/ | grep http | grep tcp' (for http ports info).
# 80     > http
# 443    > https
# 21     > ftp
# 115    > sftp
# 25     > smtp 
# 110    > Pop3
# ???    > pop3S
# 143    > IMAP
# 993    > IMAPs
# ????   > Java (apache tomcat)
# ????   > C# (asp, like :8083)
# more ...
#
# <<< Do not open list, but maybe necessary for the server administration (from my notebook): >>>
#
# ??? > NFS (Avoid it or only let it be local)
# 8222   > Tomcat http VMware (not needed is on foobar (192.168.1.4))
# 8333   > Tomcat https VMware (not needed is on foobar (192.168.1.4))
# 22     > ssh default port
# ????   > ssh changed to other port higher than the port 1024.
# 23     > telnet (had to be explicitly denied using netfilter rules. Can be used to connect to other port,
#          for example 'sh> telnet 192.168.1.6 80', then type 'HEAD' and press ENTER key)
# 10024  > amavis listening for postfix mail (open not needed, the loopback has free reign)
# 10025  > postfix listening amavis mail (open not needed, loopback has free reign)
# Remote Desktop > 3389
# 5900    > Real VNC
# PC Anywhere > 5631
# 3306   > mysql. phpmyadmin uses 3306 and is not affected. MYSQL server in other machine needs both ports open.
# ????   > ICMP (The Internet Control Messaging Proto, for Internet equip communication. Includes: 
#          server, router, etc.
#          The port can be open periodically (in ms) in order to help costumers to find,
#          for example a web server. Setup this in other script file). That script will
#          help with other script that do ping to a place, also periodically,
#          to maintain open the Internet connection's portished against DOS attacks and bottlenecks,
#          but i don't need that script, my router comes with a check to the anti DOS attacks
#          integrated option, out of the box. Anyway enforce in the firewall and every machine with
#          hardware and software is always the best decision to forge the knight's shield.
# 873    > rsync. Maybe required for the ftp-backup server.
# 992   > telnets. Secure telnet.
# 2049  > NFS. Port for Net File System, require to make grow the /var partition.
# 3690   > svn. 
# 5060  > sip.
# 5061  > sip-tls.
# 5190  > aol.
# 1194   > openvpn.
# 194   > irc.
# more...


# Accept inbound packets that are part of previously-OK'ed sessions
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# SERVER AND HOST CLUSTER RULES:

# Accept inbound packets which initiate SSH sessions
# Remeber the default and changed ports
#iptables -A INPUT -p tcp -j ACCEPT --dport 22 -m state --state NEW
#iptables -A INPUT -p tcp -j ACCEPT --dport 49 -m state --state NEW
# --== Next line changed to limit to a local host access the server through ssh.==--
# The address can be an Intranet firewall (with static IP), facing the bastion server behind the DMZ.
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.10 --dport 49 -m state --state NEW
# --== Next are activated to preserve the local host address (e.g. my notebook) like dynamic
# where my notebook ip change sometimes in a network of 5 computers, the router is configured
# to give dynamic IPs beginning from 192.168.1.10 ==--
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.10 --dport 49 -m state --state NEW
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.11 --dport 49 -m state --state NEW
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.12 --dport 49 -m state --state NEW
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.13 --dport 49 -m state --state NEW
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.14 --dport 49 -m state --state NEW

# --== Next is the template just in case we need more open, for a specific host ==--
#iptables -A INPUT -p tcp -j ACCEPT -s 192.168.1.10 --dport 49 -m state --state NEW

# To Accept packets from trusted network:
#iptables -A INPUT -s 192.168.0.0/24 -j ACCEPT  # using standard slash notation
#iptables -A INPUT -s 192.168.0.0/255.255.255.0 -j ACCEPT  # using a subnet mask

# Accept inbound packets which initiate ssh sessions from hosts in the network 192.168.1.0,
# which is supposed to be the local cluster network (I.E: hosts named x1, x2, foobar, vgui).
iptables -A INPUT -s 192.168.1.0/255.255.255.0 -p tcp -j ACCEPT --dport 22 -m state --state NEW

# To Accept packets from trusted IP addresses, for client hosts with many active ethernet interfaces,
# It's not the ssh client that decides through which interface TCP packets should go (to reach a server
# behind a firewall like this), it's the kernel. In short, SSH asks the kernel to open a connection to
# a certain IP address, and the kernel decides which interface is to be used by consulting the routing
# tables. In this case you will have to add one policy for every ethernet IP in the host. Also, you can
# display the kernel routing tables with the commands route -n and/or ip route show and perhaps modify
# temporarily (or with a script) the route table to match your needs.
# Use this policy to connect to remote cluster hosts public IPs (I.E: y1, y2, foobar2, and a remote
# vgui). Otherwise I will have to leave ssh port wide open to the Internet to reach cluster servers.
#iptables -A INPUT -s 192.168.0.4 -m mac --mac-source 00:50:8D:FD:E6:32 -j ACCEPT

# Accept inbound packets which initiate NTP (Network Time Protocol) sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 123 -m state --state NEW

# Accept inbound packets which initiate MySQL Cluster sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 1186 -m state --state NEW


# USER SERVICES RULES:

# Accept inbound packets which initiate FTP sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 21 -m state --state NEW

# --= Next new lines are specific for FTP, if you have troubles with the
# FTP passive mode. For the most of configurations it is only necessary
# the installation of the module ftp-conntrack, put the rules in the the headers of the chains 
# INPUT and OUTPUT, and finally establish the rules to the INPUT chain to let be new connections
# in the TCP port 21. If that does not work, use 2 lines here: ==--

#iptables -A INPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED,RELATED -j ACCEPT


# Accept inbound packets which initiate HTTP sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 80 -m state --state NEW

# Accept inbound packets which initiate HTTPS sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 443 -m state --state NEW

# Accept inbound packets which initiate IMAP sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 143 -m state --state NEW

# Accept inbound packets which initiate IMAP3 sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 220 -m state --state NEW

# Accept inbound packets which initiate IMAPS sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 993 -m state --state NEW

# Accept inbound packets which initiate POP2 sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 109 -m state --state NEW

# Accept inbound packets which initiate POP3 sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 110 -m state --state NEW

# Accept inbound packets which initiate POP3S sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 995 -m state --state NEW

# Accept inbound packets which initiate SMTP sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 25 -m state --state NEW

# Accept inbound packets which initiate SSMTP sessions
iptables -A INPUT -p tcp -j ACCEPT --dport 465 -m state --state NEW


# --== Next is the protocol template just in case we need more open to all client hosts ==-- 
# Accept inbound packets which initiate PROTOCOL-HERE sessions
#iptables -A INPUT -p tcp -j ACCEPT --dport 80 -m state --state NEW


# Log and drop anything not accepted above
#   (Obviously we want to log any packet that doesn't match any ACCEPT rule, for
#    both security and troubleshooting. Note that the final "DROP" rule is 
#    redundant if the default policy is already DROP, but redundant security is
#    usually a good thing.)
iptables -A INPUT -j LOG --log-prefix "Dropped by default (INPUT):"
iptables -A INPUT -j DROP

# OUTBOUND POLICY
#   (Applies to packets sent to the network interface (NOT loopback)
#   from local processes)

# If it's part of an approved connection, let it out
iptables -I OUTPUT 1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow outbound ping 
#   (For testing only! If someone compromises your system they may attempt
#   to use ping to identify other active IP addresses on the DMZ. Comment
#   this rule out when you don't need to use it yourself!)
#
#iptables -A OUTPUT -p icmp -j ACCEPT --icmp-type echo-request 

# Allow outbound DNS queries, e.g. to resolve IPs in logs
#   (Many network applications break or radically slow down if they
#   can't use DNS. Although DNS queries usually use UDP 53, they may also use TCP 
#   53. Although TCP 53 is normally used for zone-transfers, DNS queries with 
#   replies greater than 512 bytes also use TCP 53, so we'll allow both TCP and UDP 
#   53 here
#
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT


# SERVER AND HOST CLUSTER RULES:

# All the ssh output is accepted:
# Accept inbound packets which initiate ssh sessions from hosts in the network 192.168.1.0
iptables -A OUTPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate NTP (Network Time Protocol) sessions
iptables -A OUTPUT -p tcp --dport 123 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate MySQL Cluster sessions
iptables -A OUTPUT -p tcp --dport 1186 -m state --state NEW -j ACCEPT


#---------- Mail service outs:

# Accept inbound packets which initiate IMAP sessions
iptables -A OUTPUT -p tcp --dport 143 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate IMAP3 sessions
iptables -A OUTPUT -p tcp --dport 220 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate IMAPS sessions
iptables -A OUTPUT -p tcp --dport 993 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate POP2 sessions
iptables -A OUTPUT -p tcp --dport 109 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate POP3 sessions
iptables -A OUTPUT -p tcp --dport 110 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate POP3S sessions
iptables -A OUTPUT -p tcp --dport 995 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate SMTP sessions
iptables -A OUTPUT -p tcp --dport 25 -m state --state NEW -j ACCEPT

# Accept inbound packets which initiate SSMTP sessions
iptables -A OUTPUT -p tcp --dport 465 -m state --state NEW -j ACCEPT

#------------


# Log & drop anything not accepted above; if for no other reason, for troubleshooting
#
# NOTE: you might consider setting your log-checker (e.g. Swatch) to
#   sound an alarm whenever this rule fires; unexpected outbound trans-
#   actions are often a sign of intruders!
#
iptables -A OUTPUT -j LOG --log-prefix "Dropped by default (OUTPUT):"
iptables -A OUTPUT -j DROP

# Log & drop ALL incoming packets destined anywhere but here.
#   (We already set the default FORWARD policy to DROP. But this is 
#   yet another free, reassuring redundancy, so why not throw it in?)
# Attempted FWD? Dropped by default:
#
iptables -A FORWARD -j LOG --log-prefix "FWD Dropped by default:"
iptables -A FORWARD -j DROP


exit 1

