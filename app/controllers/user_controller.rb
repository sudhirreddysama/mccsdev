class UserController < CrudController

	def index
		@filter = get_filter({
			:sort1 => 'users.username',
			:dir1 => 'asc'
		})
		@orders = [
			['ID', 'users.id'],
			['Username', 'users.username'],
			['Name', 'users.name'],
			['Initials', 'users.initials'],
			['Level', 'users.level'],
			['Agency Name', 'agencies.name']
		]
		cond = get_search_conditions @filter[:search], {
			'users.id' => :left,
			'users.username' => :like,
			'users.name' => :like,
			'users.level' => :like,
			'users.initials' => :like,
			'agencies.name' => :like 
		}
		
		@opt = {
			:conditions => get_where(cond),
			:order => get_order_auto,
			:include => :agency
		}
		super
	end
	
	def user_flip
		session[:current_user_id] = params[:id]
		render :text => 'flip'
	end

end