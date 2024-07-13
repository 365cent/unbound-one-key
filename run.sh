#!/bin/bash

# Install Unbound
apt update && apt install -y unbound

# Backup original unbound configuration
cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.backup

# Create a new unbound configuration
cat > /etc/unbound/unbound.conf << EOF
server:
    # Use system DNS settings for local resolving (can be customized if needed)
    interface: 127.0.0.1
    port: 53
    do-ip4: yes
    do-udp: yes
    do-tcp: yes

    # Access control: allow localhost
    access-control: 127.0.0.0/8 allow

    # Not to be used as a public DNS resolver
    access-control: 0.0.0.0/0 refuse

    # Enable caching and minimize DNS traffic
    cache-max-ttl: 86400
    cache-min-ttl: 3600
    prefetch: yes
    prefetch-key: yes

    # Forwarding to other DNS servers based on latency
    forward-zone:
        name: "."
        # Use multiple forward-addr entries with different DNS providers
        forward-addr: 1.1.1.1@53        # Cloudflare
        forward-addr: 8.8.8.8@53        # Google
        forward-addr: 9.9.9.9@53        # Quad9
EOF

# Restart Unbound to apply changes
service unbound restart

# Overwrite /etc/resolv.conf to use Unbound as the local DNS resolver
cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
EOF

# Prevent the resolv.conf file from being overwritten by the system
chattr +i /etc/resolv.conf

echo "Unbound installation and configuration completed. System is now using its own caching DNS resolver."
