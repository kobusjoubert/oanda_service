class User < ApplicationRecord
  acts_as_token_authenticatable

  # Include default devise modules. Others available are:
  # :trackable, :validatable, :registerable, :recoverable, :rememberable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable
end
