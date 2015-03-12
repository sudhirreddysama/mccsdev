class SeasonalApp < ActiveRecord::Base

	has_many :documents
	
	validates_presence_of :name
	
	def label
		"#{created_at.d0?} #{name_was}"
	end
	
	# NOT USED.
	def self.cron
		return false
		apps = []
		Mail.defaults {
			retriever_method(:pop3, {
				:address    => 'mail.discoveregov.com',
				:user_name  => 'mccs-seasonal@discoveregov.com',
				:password   => 'ccs4ever'
			})
		}	
		emails = Mail.all({:delete_after_find => true})
		emails.each { |email|
			body = email.multipart? ? email.parts[0].body : email.body
			app = SeasonalApp.create({
				:name => email.from[0],
				:email_raw => email.raw_source,
				:email_subject => email.subject,
				:email_type => body.mime_type,
				:email_body => body.decoded
			})
			apps << app
			email.attachments.each { |att|
				temp = TempfileExt.open att.filename, 'tmp'
				temp.write att.decoded
				temp.close
				doc = Document.create({:seasonal_app => app, 
					:uploaded_file => {
						:path => temp.path,
						:original_filename => att.filename
					}
				})
			}
		}
		apps.each { |a|
			a.documents.each { |d|
				if File.extname(d.filename).downcase == '.pdf'
					attr = d.pdftk_dump_data_fields
					if attr['ssn'] && attr['name']
						attr.delete 'signature'
						attr.delete 'submit'
						a.update_attributes attr
						break
					end
				end
			}
		}
	end
	
	def positions
		w = []
		w << 'Parks Seasonal Laborer' if seasonal_laborer_parks
		w << 'Seasonal GEO' if seasonal_geo
		w << 'Lifeguard' + (lifeguard_certifications ? ' (has certifications)' : ' (NO CERTIFICATIONS)') if lifeguard
		w << 'DOT Seasonal Laborer' if seasonal_laborer_dot
		w << 'Environmental Aide' if environmental_aide
		w << 'Laboratory Aide' if laboratory_aide
		w << "Other: #{other_job}" unless other_job.blank?
		w << "Park: #{park_preference}" if !park_preference.blank? && park_preference != 'Any Park'
		return w
	end
	
	def full_address j = "\n"
		[address, [[city, state].reject(&:blank?).join(', '), zip_code].reject(&:blank?).join(' ') ].reject(&:blank?).join(j)
	end
	
end