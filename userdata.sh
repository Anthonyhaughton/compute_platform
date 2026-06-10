#!/bin/bash
# Update system packages
dnf update -y

# Install Apache HTTP Server
dnf install -y httpd

# Create the custom index.html file
cat << 'EOF' > /var/www/html/index.html
<html>
<body>
    <h1>Hello from the Compute Platform</h1>
</body>
</html>
EOF

# Start the Apache service
systemctl start httpd

# Enable Apache to start automatically on system boot
systemctl enable httpd
