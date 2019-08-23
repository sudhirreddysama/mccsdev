class FormAction < ActiveRecord::Base

	belongs_to :obj, :polymorphic => true
	belongs_to :user
	belongs_to :recipient, :class_name => 'User'

end