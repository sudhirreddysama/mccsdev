class Document < ActiveRecord::Base
	
	belongs_to :employee
	belongs_to :job
	belongs_to :exam
	belongs_to :web_exam
	belongs_to :applicant
	belongs_to :cert
	belongs_to :person
	belongs_to :user
	belongs_to :cert_applicant
	belongs_to :seasonal_app
	belongs_to :preferred_candidate
	belongs_to :pay_cert
	belongs_to :provisional
	belongs_to :form_change
	belongs_to :form_hire
	belongs_to :form_title
	belongs_to :notice
	
	attr :uploaded_file, true
	
	validates_presence_of :uploaded_file, :on => :create
	validates_presence_of :filename, :on => :update

	def label; filename; end
		
	def path
		"documents/#{created_at.year}/#{created_at.month}/#{id}-#{filename}"
	end
	
	def path_was
		"documents/#{created_at.year}/#{created_at.month}/#{id}-#{filename_was}"
	end
	
	def filename_pdf
		"#{filename}.pdf"
	end
	
	def fix_filename
		if filename_changed?
			`mv "#{path_was}" "#{path}"`
		end
	end
	
	before_update :fix_filename
	
	def handle_before_create
		self.filename = uploaded_file.original_filename
		return true
	end
	before_create :handle_before_create
	
	def handle_after_create
		`mkdir documents/#{created_at.year}`
		`mkdir documents/#{created_at.year}/#{created_at.month}`
		`cp #{Shellwords.escape(uploaded_file.path)} #{Shellwords.escape(path)}`
	end
	after_create :handle_after_create
	
	def original_filename; filename; end
	
	def clone
		Document.new :uploaded_file => self
	end
	
	def txt_file?
		File.extname(filename).downcase == '.txt'
	end
	
	def parse_scores
	
		applicant_lines = []
		band_score_lines = []
		
		# First figure out what lines are applicants, which are bandscored.
		mode = nil
		bandscore_index = nil

		File.open(path).each_with_index { |l, i|
			if i == 2
				mode = 'applicant'
			end
			if l.blank?
				mode = 'empty'
			end
			if l.strip == 'BAND SCORE TABLE'
				mode = 'bandscore'
				bandscore_index = i + 2
			end
			
			if mode == 'applicant' || 	mode == 'applicant2'
				applicant_lines << l
			elsif mode == 'bandscore' && i > bandscore_index
				band_score_lines << l
			end
			
			if l.strip == '*FAILED'
				mode = 'applicant2'
			end
		}
		
		logger.info band_score_lines.inspect
		
		band_scored = !band_score_lines.empty?
	
		objs = []
		objs_indexed = {}

		applicant_lines.each { |l|
			f = l.split("\t")
			o = {
				:last_name =>  f[0].strip,
				:first_name => f[1].strip,
				:middle_name => f[2].strip,
				:ssn => f[3].strip,
			}
			if band_scored
				o[:raw_score] = f[4].strip
				o[:sr_credi] = f[5].strip
				o[:total] = f[6].strip
				o[:apply_band] = f[7].strip
				o[:final_score] = f[8].strip
				o[:vet_credi] = f[9].strip
				o[:list_score] = f[10].strip
				o[:exam] = f[11].strip
				o[:bat] = f[12].strip
				o[:seq] = f[13].strip
				o[:re] = f[14].strip
			else
				o[:final_score] = f[4].strip
				o[:v] = f[5].strip
				o[:l] = f[6].strip
				o[:exam] = f[7].strip
				o[:bat] = f[8].strip
				o[:seq] = f[9].strip
				o[:re] = f[10].strip
			end
			objs << o
			objs_indexed[o.ssn] = o
		}
		
		band_scoring = []
		band_score_lines.each { |l|
			band_scoring << {
				:from => l[0, 5].gsub('-', '').strip.to_f,
				:to => l[9, 5].gsub('-', '').strip.to_f,
				:score => l[15, 5].gsub('-', '').strip.to_f
			}
		}
		
		applicants = exam.applicants.find(:all, {
			:include => :person, 
			:conditions => 'applicants.approved = "Y"', 
			:order => 'people.last_name, people.first_name'
		})
		objs_found = []
		applicants_not_found = []
		applicants.each { |a|
			o = objs_indexed[a.person.ssn]
			if o #&& a.person.last_name.upcase == o.last_name.upcase
				o.applicant = a
				objs_found << o
			else
				applicants_not_found << a
			end
		}
		objs_not_found = []
		objs.each { |o|
			if !o.applicant
				objs_not_found << o
			end
		}
		return objs_found, objs_not_found, applicants_not_found, band_scored ? band_scoring : nil
	end
	
	def pdftk_dump_data_fields
		output = `pdftk "#{path}" dump_data_fields`
		fields = output.split('---')
		data = {}
		fields.each { |f|
			match = /FieldName: (.*)/.match(f)
			if match && match[1]
				match2 = /FieldValue: (.*)/.match(f)
				field_name = match[1]
				field_value = match2 ? match2[1] : nil
				data[field_name] = field_value
			end
		}
		return data
	end
	
	
	include DbChangeHooks
	
end