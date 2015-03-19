class SocialMediaCron

	def self.twitter
		p "Twitter CRON Started: #{Time.now}"
		client = Twitter::REST::Client.new { |config|
			config.consumer_key = 'q6WnT3FFkQbXlfSDbEGXukqLY'
			config.consumer_secret = 'JYTxpu7IdIX9tcyuH64Q7rntPtOEJccyAagcTGQwq21GT3Uvo6'
			config.access_token = '3065818631-4PzYTF3whv4ZsvP44FXbDHI8czynPEe6TzO8C3o'
			config.access_token_secret = 'kUufv8NOdWYUyoGWAaJgavgsuIoriTaOXGd3BasIRFkFV'
		}		
		exams = WebExam.find(:all, :order => 'name, no', :conditions => 'published = 1 and publish < now() and twitter_posted = 0')	
		p "Exams To Post: #{exams.length}"
		if exams.length > 0
			exams.each { |e|
				p "Posting to Twitter: #{e.id} #{e.no} #{e.name}"
				# NOTE: "Apply*Online:*" contains non-breaking space characters!
				client.update 'New Exam/Job: ' + [e.no, e.name].reject(&:blank?).join(' ') + ' Apply Online: cs.monroecounty.gov/hrapply'
				e.update_attribute :twitter_posted, true
			}
		end
		p 'Twitter CRON Ended'
	end
	
	def self.facebook
		graph = Koala::Facebook::API.new('CAAWBZA6JVCrkBAONxGl5bGFkjkJnBIrs2Wg2JfjJjWqJWZAoRzMDnRLejolOpsDC4uwq62985XWlGRDTxI12WFvifNL0D4W5AhNTE5bHBpb6Gz5CA6mPbbsVJHAujRINVajZAmpWQ8MbgZBZBilTAZA6J4sJEuZBqYskCitO4FVEGlXCNnQY60B7HYLZAFPyFTaYGFkIxUFlewZDZD')
		p "Facebook CRON Started: #{Time.now}"
		exams = WebExam.find(:all, :order => 'name, no', :conditions => 'published = 1 and publish < now() and facebook_posted = 0')	
		p "Exams To Post: #{exams.length}"
		if exams.length > 0
			message = ''
			exams.each { |e|
				p "Posting to Facebook: #{e.id} #{e.no} #{e.name}"
				message += [e.no, e.name].reject(&:blank?).join(' ') + "\n"
				e.update_attribute :facebook_posted, true
			}
			graph.put_connections('me', 'feed', :message => "New Exam/Job Announcements: \n#{message}Apply Now: cs.monroecounty.gov/hrapply")
		end
		p 'Facebook CRON Ended'
	end
	
end