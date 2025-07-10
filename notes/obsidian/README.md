# CouchDB Obsidian LiveSync Setup

./obsidian.sh up -d # Start the service
./obsidian.sh down # Stop and remove containers
./obsidian.sh logs -f # View logs
./obsidian.sh ps

### Accessing CouchDB

Once running, CouchDB will be available at:

- Web interface: http://localhost:5984/\_utils
- Database URL: http://localhost:5984

Login with the credentials you set in your `.env` file.
