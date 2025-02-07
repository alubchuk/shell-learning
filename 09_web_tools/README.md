# Module 9: Web Tools (curl and wget)

This module covers two essential command-line tools for web operations: curl and wget. These tools are crucial for downloading files, interacting with web APIs, and automating web-related tasks.

## curl (Client URL)

### Basic Operations
- HTTP GET requests
- HTTP POST requests
- Custom headers
- Authentication
- Following redirects

### Advanced Features
- Cookie handling
- SSL/TLS options
- Proxy support
- Progress meters
- Multiple transfers
- Resume downloads

### Common Use Cases
- API testing
- Web scraping
- File download
- Site monitoring
- OAuth authentication
- WebSocket connections

## wget (Web Get)

### Basic Operations
- Single file download
- Recursive download
- Background downloads
- Mirror websites
- Authentication

### Advanced Features
- Download quotas
- Timestamping
- Retry mechanisms
- Spider mode
- FTP support
- Conversion options

### Common Use Cases
- Website mirroring
- Batch downloads
- Automated backups
- Recursive retrieval
- Site archiving

## Key Differences

### curl
- More feature-rich for API interactions
- Better for complex HTTP operations
- Supports more protocols
- Output can be customized
- Better for scripting and automation

### wget
- Better for recursive downloads
- More suitable for large files
- Built-in retry mechanism
- Spider mode for website checking
- Simpler command syntax

## Examples in this Module

1. `01_curl_basics.sh`: Basic curl operations
   - HTTP methods
   - Headers and data
   - Authentication
   - Progress tracking

2. `02_curl_advanced.sh`: Advanced curl features
   - API interactions
   - File upload/download
   - Cookie handling
   - SSL operations

3. `03_wget_basics.sh`: Basic wget operations
   - Single downloads
   - Recursive downloads
   - Authentication
   - Progress tracking

4. `04_wget_advanced.sh`: Advanced wget features
   - Website mirroring
   - Batch processing
   - Spider mode
   - Custom logging

5. `05_practical_example.sh`: Web Automation Framework
   - API testing suite
   - Website monitoring
   - Batch download manager
   - Site backup tool
