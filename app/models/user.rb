class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :registerable, 
         :recoverable, :rememberable, :omniauthable,
         authentication_keys: [:line_id]
  validates_uniqueness_of :line_id

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end

  
end
