class Bandscore < ActiveRecord::Base
	
	belongs_to :exam
	
	def apply_scoring
	
		bs = []
		1.upto(11) { |i|
			rg = eval "rg#{i}"
			gd = eval "gd#{i}"
			if !rg.blank? && !gd.blank?
				from_to = rg.split('-')
				from = from_to[0].to_f rescue nil
				to = from_to[1].to_f rescue nil
				grade = gd.to_f rescue nil
				if from && to && grade
					bs << {:from => from, :to => to, :grade => grade}
				end
			end
		}
		bs = bs.sort_by(&:grade).reverse # top score first
		exam.applicants.each { |a|
			use_score = a.raw_score.to_f + a.other_credits.to_f
			b = bs.find { |b|	
				# Now that top scores are first, we can assume if they hit the minimum they should get that score.
				use_score >= b.from # && use_score <= b.to
			}
			if b
				a.base_score = b.grade
				a.final_score = a.base_score + a.veterans_credits.to_f
				a.save
			end
		}
	end
	
	include DbChangeHooks
	
end