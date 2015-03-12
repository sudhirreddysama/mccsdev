class Const

	PREF_LIST_STATUSES = [
		'established',
		'requested',
		'certified',
		'complete',
		'exhausted'
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
	
	JOB_CLASSES = [
		['UNCLASSIFIED', 'U'],
		['COMPETITIVE', 'C'],
		['NON-COMPETITIVE', 'N'],
		['SPECIAL NON-COMPETITIVE (55A)', '5'],
		['LABOR', 'L'],
		['EXEMPT', 'E'],
		['PENDING CLASSIFICATION', 'D']
	]
	
	GIVEN_BY = [
		['State Decentralized', 1],
		['State Prepared and Rated', 2],
		['Locally Prepared and Rated', 3]
	]
	
	JOB_STATUSES = [
		['PERMANENT', 'P'],
		['PROVISIONAL', 'V'],
		['PROVISIONAL-2ND', 'V2'],
		['CONTINGENT-PERMANENT', 'C'],
		['TEMPORARY', 'T'],
		['SEASONAL', 'S'],
		['SUBSTITUTE', 'SU'],
		['PENDING-NYS', 'PN']
	]
	
	JOB_TIMES = [
		['FULL TIME', 'F'],
		['PART TIME', 'P']
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
		['Agency user, can only view basic employee information', 'agency-employees'],
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
		['UNKNOWN', nil],
		['NON-VET', 'NON-VET'],
		['VETERAN', 'VETERAN'],
		['DISABLED VET', 'DISABLED VET']
	]
	
end