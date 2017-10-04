class Contact < ActiveRecord::Base

  belongs_to :agency
  belongs_to :department
  def label; lastname; end

	include DbChangeHooks

end