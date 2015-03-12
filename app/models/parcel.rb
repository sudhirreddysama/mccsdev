class Parcel < ActiveRecord::Base

	def self.locate adr, zip
		
		return if !zip or !adr
		
		zip5 = zip[0, 5]
		
		# Check if they entered the whole address in the field by detecting a zip code.
		parts = adr.split ' '
		last = parts.last
		if last.match /\d\d\d\d\d(.\d\d\d\d)?/
			3.times { # City, State and zip
				parts.pop
			}
			adr = parse.join ' '
		end
		
		# Remove " Apt 123".
		adr.gsub! /\ apt.*\Z/i, ''
		
		# Remove " Apartment 123".
		adr.gsub! /\ apartment.*\Z/i, ''
		
		# Remove punctuation.
		adr.gsub! /(,|.)\Z/i, ''
		
		# Remove whitespace.
		adr.strip!
		
		# Try to find verbatim.
		p = Parcel.find :first, :conditions => ['address like ? and left(PAR_ZIP, 5) = ?', adr, zip5]
		
		return p if p
		
		# Get the street number & type & dir.
		parts = adr.split ' '
		no = parts.shift.to_i
		pdir = ''
		sdir = ''
		dirs = %w{N E S W North East South West}
		
		typ = parts.pop.to_s
		
		adr = parts.join ' '
		

		
		
		# Find type aliases
		types = []
		DB.query('select t2.common from street_types t1 join street_types t2 on t2.full = t1.full where t1.common like "%s"', typ).each_hash { |r| types << r['common'] }
		types = [typ] if types.empty?
		
		# Try to find address for each type.
		types.each { |t|
			p = Parcel.find :first, :conditions => ['address like ? and left(PAR_ZIP, 5) = ?', "#{no} #{adr} #{t}", zip5]
			return p if p
		}
		
		# Try to find an apartment building, with the number formatted like "120-130".
		types.each { |t|
			Parcel.find(:all, :conditions => ['address like ? and left(PAR_ZIP, 5) = ? and ST_NBR like "%-%"', "%#{adr} #{t}", zip5]).each { |p|
				apt_start, apt_end = p.ST_NBR.split('-').collect &:to_i
				return p if no <= apt_end and no >= apt_start
			}
		}
		
		# Doh.
		return nil
		
	end
	
	# For testing the effectiveness of above locate().
	def self.profile
		aps = Applicant.find :all, :conditions => ['submit_complete = 1 and town = "" or town is null and county = "MONROE"']
		w = 0
		c = 0
		aps.each { |a|
			adr = a.residence_different ? a.res_address : a.address
			zip = a.residence_different ? a.res_zip : a.zip
			unless zip.blank?
				parcel = Parcel.locate adr, zip
				w += 1
				if parcel
					c += 1
				else
					p "#{a.id}, #{adr}, #{zip}"
				end
			end
		}
		puts "Found: #{c}/#{w}"
	end

end