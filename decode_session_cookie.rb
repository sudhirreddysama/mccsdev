#!/usr/bin/ruby
require 'openssl'
require 'base64'
require 'openssl'
        
#require 'json'
#require 'yaml'


def secure_compare(a, b)
	if a.length == b.length
		result = 0
		for i in 0..(a.length - 1)
			result |= a[i] ^ b[i]
		end
		result == 0
	else
		false
	end
end

# Dummy classes for unmarshalling errors.
class ActionController
	class Flash
		class FlashHash < Hash
		end
	end
end
class HashWithIndifferentAccess < Hash; end


#session_cookie = 'BAh7CjoUY3VycmVudF91c2VyX2lkaQGjIhZleGFtX2luZGV4X2ZpbHRlcnsHOgpzb3J0MSINZXhhbXMuaWQ6CWRpcjEiCWRlc2MiCmZsYXNoSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA6D3Nlc3Npb25faWQiJTU4ZDBkNTcxNDI5NzlmMTA5M2FhZDlkMmU5ZGM4ZTljOhRzd2l0Y2hfdXNlcl9pZHNbGGkBo2kGaRRpGmkdaSRpJWlOaVRpcmkBlGkBlmkBsGkCQgFpAdZpAfFpAg8BaQISAWkCEwE=--4684a541a9576e0c1ad2741ca308827012b26ff2'
session_cookie = ARGV[0]
secret_key_base = '30eaa43e6eff615814adda2a6fa31e65e5aa15adf3e27d3a0ed2d0b25120ad00c9c4aa2e225e97a89c65ea89711882c2d7a44002691ad92c811149a956cc2604'

data, digest = session_cookie.split("--")
check = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('SHA1'), secret_key_base, data)
if secure_compare(digest, check)
	serialized = data.unpack("m").first
	session = Marshal.load(serialized)
	puts "{\"current_user_id\": #{session[:current_user_id]}}"
end

#secrets = YAML.load_file(__dir__ + '/config/secrets.yml')
#secret_key_base = secrets[Dir.pwd.include?('/biddev') ? 'development' : 'production']['secret_key_base']
#session_cookie = ARGV[0]
#cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc').tap(&:decrypt)
#cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(secret_key_base, 'encrypted cookie', 1000, 64)[0,32] # salt, iterations, key length
#unpack64 = lambda { |str| str.unpack("m").first }
#encrypted_data, cipher.iv = session_cookie.split("--").map(&unpack64).first.split("--").map(&unpack64)
#puts(cipher.update(encrypted_data) + cipher.final)




