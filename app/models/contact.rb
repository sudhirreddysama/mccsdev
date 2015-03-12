class Contact < ActiveRecord::Base

  belongs_to :agency
  def label; lastname; end


end