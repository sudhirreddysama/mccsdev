class Delivery < ActiveRecord::Base

	has_many :messages
	belongs_to :user

	def label; created_at.dt0?; end

	include DbChangeHooks
	
end