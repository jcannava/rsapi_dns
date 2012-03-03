require 'rubygems'
require 'rest_client'
require 'json'
require 'simplehttp'

auth_url = 'https://identity.api.rackspacecloud.com/v1.1/auth'
dns_url = 'https://dns.api.rackspacecloud.com/v1.0/'
toplevel = <toplevel domain, i.e. example.com>
recordname = <record name, i.e. dummy.example.com>
username = <api username>
apikey = <api key>
account = <api account number, gathered from X-Server-Management Url in the response headers from auth>
token = nil
domain_id = nil
record_id = nil

# Authenticate / Get API Token
auth_url = auth_url + account
response = RestClient.post auth_url, {'credentials' => {'username' => username, 'key' => apikey}}.to_json, :content_type => :json, :accept => :json
parsed = JSON.parse(response.body)
token = parsed['auth']['token']['id']

# Get List of domains from RS DNS
domain_list = RestClient.get dns_url + "/domains", :content_type => :json, :accept => :json, :X_Auth_Token => token
parsed = JSON.parse(domain_list.body)
parsed['domains'].each do |domain|
    if domain['name'] == toplevel
        domain_id = domain['id']
    end
end

# Get Record Information 
dns_url = dns_url + "/domains/" + domain_id.to_s + "/records"
records_list = RestClient.get dns_url, :content_type => :json, :accept => :json, :X_Auth_token => token
parsed = JSON.parse(records_list.body)
parsed['records'].each do |record|
    if record['name'] == recordname
        record_id = record['id']
    end
end

# Get Record Details
dns_url = dns_url + "/" + record_id.to_s
records_detail = RestClient.get dns_url, :content_type => :json, :accept => :json, :X_Auth_token => token
parsed = JSON.parse(records_detail.body)
record_ip = parsed['data']

# Get my current IP address
ip = SimpleHttp.get "http://automation.whatismyip.com/n09230945.asp"

# Check results and modify dns provider result if applicable
if record_ip != ip 
    update_ip = RestClient.put dns_url, {'name' => recordname, 'content' => ip, 'ttl' => 3600}.to_json, :content_type => :json, :accept => :json
    if update_ip.code != 200 
        print "FAILED TO UPDATE: " + update_ip.body + "\n"
    else
        print "Update successful\n"
    end
else 
    print "Nothing to update\n"
end
