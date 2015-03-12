class WebAttachment < ActiveRecord::Base

	set_table_name "#{HRAPPLYDB}.attachments"
	
	def path
		"/home/rails/hrapply/attachments/#{id}#{File.extname(name)}"
	end
	
	def pdf_path
		"/home/rails/hrapply/attachments/#{id}.pdf"
	end	
	
end