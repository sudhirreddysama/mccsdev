class SocialMediaCron

	def self.twitter
		client = Twitter::REST::Client.new { |config|
			config.consumer_key = 'q6WnT3FFkQbXlfSDbEGXukqLY'
			config.consumer_secret = 'JYTxpu7IdIX9tcyuH64Q7rntPtOEJccyAagcTGQwq21GT3Uvo6'
			config.access_token = '3065818631-4PzYTF3whv4ZsvP44FXbDHI8czynPEe6TzO8C3o'
			config.access_token_secret = 'kUufv8NOdWYUyoGWAaJgavgsuIoriTaOXGd3BasIRFkFV'
		}
		client.update 'First Tweet! Hello!'
	end
	
	def self.facebook
	
		graph = Koala::Facebook::API.new('CAAWBZA6JVCrkBAONxGl5bGFkjkJnBIrs2Wg2JfjJjWqJWZAoRzMDnRLejolOpsDC4uwq62985XWlGRDTxI12WFvifNL0D4W5AhNTE5bHBpb6Gz5CA6mPbbsVJHAujRINVajZAmpWQ8MbgZBZBilTAZA6J4sJEuZBqYskCitO4FVEGlXCNnQY60B7HYLZAFPyFTaYGFkIxUFlewZDZD')
		graph.put_connections('me', 'feed', :message => 'Third Facebook Post! Hello Again and Again!')
	end
	
end