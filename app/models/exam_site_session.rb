class ExamSiteSession < ActiveRecord::Base
	
	belongs_to :exam_site
	
	# Delete non existent sessions, then look at when exams are given and the exam sites to populate sessions. 
	def self.refresh
		DB.query('
			delete s from exam_site_sessions s
			left join (
				select distinct a.exam_site_id, date(e.given_at) given_on
				from applicants a 
				join exams e on e.id = a.exam_id 
				where e.given_at is not null and a.exam_site_id is not null
			) a on a.exam_site_id = s.exam_site_id and a.given_on = s.given_on
			where a.exam_site_id is null		
		')
		DB.query('
			insert into exam_site_sessions (exam_site_id, given_on, label)
			select distinct a.exam_site_id, date(e.given_at) given_on, group_concat(distinct e.exam_no separator ", ") label
			from applicants a 
			join exams e on e.id = a.exam_id
			where e.given_at is not null and a.exam_site_id is not null
			group by a.exam_site_id, given_on
			order by e.given_at asc
			on duplicate key update label = values(label)
		')
	end

end