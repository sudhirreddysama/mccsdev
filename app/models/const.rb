class Const

	def self.rassoc_to_hash arr
		Hash[*arr.map(&:reverse).flatten]
	end

	PREF_LIST_STATUSES = [
		'established',
		'requested',
		'certified',
		'complete',
		'exhausted',
		'expired'
	]

	AGENCY_TYPES = [
      'FIRE DISTRICT',
		'TOWN',
		'SCHOOL DISTRICT',
		'SPECIAL DISTRICT',
		'COUNTY',
		'VILLAGE',
		'LIBRARY',
		'CITY'
	]
	
	jc = JobClass.find(:all, :order => 'sort').to_a
	
	JOB_CLASSES = jc.map { |c| [c.description, c.code] }
	JOB_CLASSES_SHORT = jc.map { |c| [c.short, c.code] }
	
# 	JOB_CLASSES = [
# 		['UNCLASSIFIED', 'U'],
# 		['COMPETITIVE', 'C'],
# 		['NON-COMPETITIVE', 'N'],
# 		['55A NON-COMPETITIVE', '5'],
# 		['LABOR', 'L'],
# 		['EXEMPT', 'E'],
# 		['PENDING CLASSIFICATION', 'D']
# 	]
	JOB_CLASSES_HASH = rassoc_to_hash JOB_CLASSES
	
# 	JOB_CLASSES_SHORT = [
# 		['UNCLASS', 'U'],
# 		['COMP', 'C'],
# 		['NON-COMP', 'N'],
# 		['55A', '5'],
# 		['LABOR', 'L'],
# 		['EXEMPT', 'E'],
# 		['PENDING', 'D']
# 	]
	JOB_CLASSES_SHORT_HASH = rassoc_to_hash JOB_CLASSES_SHORT
	
	GIVEN_BY = [
		['State Decentralized', 1],
		['State Prepared and Rated', 2],
		['Locally Prepared and Rated', 3]
	]
	
	js = JobStatus.find(:all, :order => 'sort').to_a
	
	JOB_STATUSES = js.map { |s| [s.name, s.code] }
	JOB_STATUSES_HASH = rassoc_to_hash JOB_STATUSES
	JOB_STATUSES_SHORT = js.map { |s| [s.short, s.code] }
	JOB_STATUSES_SHORT_HASH = rassoc_to_hash JOB_STATUSES_SHORT
	
# 	JOB_STATUSES = [
# 		['PERMANENT', 'P'],
# 		['PROVISIONAL', 'V'],
# 		['PROVISIONAL-2ND', 'V2'],
# 		['CONTINGENT-PERMANENT', 'C'],
# 		['TEMPORARY', 'T'],
# 		['SEASONAL', 'S'],
# 		['SUBSTITUTE', 'SU'],
# 		['PENDING-NYS', 'PN']
# 	]
	
# 	JOB_STATUSES_SHORT = [
# 		['PERM', 'P'],
# 		['PROV', 'V'],
# 		['PROV2', 'V2'],
# 		['CONT-PERM', 'C'],
# 		['TEMP', 'T'],
# 		['SEASONAL', 'S'],
# 		['SUB', 'SU'],
# 		['PEND-NYS', 'PN']
# 	]
	
	JOB_TIMES = [
		['FULL TIME', 'F'],
		['PART TIME', 'P']
	]
	
	JOB_TIMES_SHORT = [
		['FULL', 'F'],
		['PART', 'P']
	]
	
	JOB_TIMES_ABBR = [
		['FT', 'F'],
		['PT', 'P']
	]
	
	# Note: Some records from the old system have strange wage units.
	WAGE_UNITS = [
		['HOUR', 'H'],
		['DAY', 'D'],
		['WEEK', 'W'],
		['BIWEEK', 'B'],
		['SEMIMONTH', 'S'],
		['MONTH', 'M'],
		['QUARTER', 'Q'],
		['YEAR', 'Y'],
		['UNIT', 'U']
	]
	
	USER_LEVELS = [
		['Disabled user, cannot login.', 'disabled'],
		['Civil Service staff, can access entire system.', 'staff'],
		['Staff level + can edit users.', 'admin'],
		['Can access entire system, but is view only.', 'view-only'],
		['Can make updates under the employee tab, otherwise view only.', 'liaison'],
		['Agency user, can only access agency specific data.', 'agency'],
		#['Agency user, can only view basic employee information', 'agency-employees'],
		['Agency user who can also sign and return certified lists.', 'agency-head']
	]
	
	PAID_BY = [
		['Check', 'K'],
		['Credit', 'R'],
		['Cash', 'C'],
		['Reg. Waiver', 'W'],
		['Empl. Waiver', 'E'],
		['Money Order', 'M'],
		['Bounced Check', 'B'],
		['Unpaid', 'U'],
		['No Charge', 'X']
	]
	
	EXAM_TYPES = [
		['Open Competitive', 'OC'],
		['Promotional', 'PROM'],
		['Non-Competitive Promotional', 'NCP']
	]
	
	CALCULATOR_TEXT = [
		'ALLOWED',
		'RECOMMENDED',
		'PROHIBITED'
	]
	
	VETERAN_TYPES = [
		['NON-VET', ''],
		['VETERAN', 'VETERAN'],
		['DISABLED VET', 'DISABLED VET'],
		['ACTIVE DUTY', 'ACTIVE DUTY']
	]
	
	UNIONS = [
		['CSEA', '01'],
		['FSW', '02'],
		['IUOE', '03'],
		['IAFF', '04'],
		['Department Head', '05'],
		['Management and Confi', '06'],
		['Management & Professional', '07'],
		['Sheriff\'s Command', '08'],
		['LEA', '09'],
		['PBA', '10'],
		['DSA', '11'],
		['Elected Official, Co', '12'],
		['Sheriff\'s Exec Staff', '13'],
		['Non-union', '14'],
		['Non-union PT w/o Ben', '15'],
		['CSEA PT', '16'],
		['FSW PT w/ Benefits', '17'],
		['FSW-PT/Seas/PD,w/oBN', '18'],
		['Temporary', '19'],
		['Seasonal', '20'],
		['IUOE Part-Time', '27'],
	]
	
	HR_STATUSES = ['dept', 'liaison', 'exam-mgr', 'hr-mgr', 'hr-director', 'liaison-final', 'payroll', 'benefits', 'done']
	
end