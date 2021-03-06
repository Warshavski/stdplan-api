# frozen_string_literal: true

# User
#
#   Represents a registered user
#
class User < ApplicationRecord
  include AvatarUploader[:avatar]

  include CaseSensible
  include Searchable

  STATUSES      = %w[active confirmed banned].freeze
  MAILING_TYPES = %w[unlock confirmation].freeze

  DEFAULT_TIMEZONE = 'UTC'

  #
  # Include default devise modules. Others available are:
  #
  #   - :timeoutable
  #   - :omniauthable
  #
  devise :database_authenticatable, :lockable, :recoverable, :rememberable,
         :trackable, :validatable, :confirmable, :registerable

  #
  # Virtual attribute for authenticating by either username or email
  #
  attr_accessor :login

  has_many :access_grants,
           class_name: 'Doorkeeper::AccessGrant',
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :access_tokens,
           class_name: 'Doorkeeper::AccessToken',
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_one :recent_access_token, -> { order(id: :desc) },
          class_name: 'Doorkeeper::AccessToken',
          foreign_key: :resource_owner_id,
          dependent: :delete

  has_one :student, dependent: :destroy

  has_many :reported_bugs,
           class_name: 'BugReport',
           foreign_key: :reporter_id,
           inverse_of: :reporter,
           dependent: :delete_all

  has_one :abuse_report,
          foreign_key: :user_id,
          inverse_of: :user,
          dependent: :destroy

  has_one :status,
          class_name: 'UserStatus',
          inverse_of: :user,
          dependent: :delete

  has_many :reported_abuses,
           foreign_key: :reporter_id,
           class_name: 'AbuseReport',
           inverse_of: :reporter,
           dependent: :destroy

  has_many :identities, dependent: :destroy

  has_many :uploads,
           class_name: 'Attachment',
           inverse_of: :author,
           dependent: :destroy

  has_many :audit_events, foreign_key: :author_id, dependent: :delete_all

  has_many :activity_events, foreign_key: :author_id, dependent: :delete_all

  accepts_nested_attributes_for :student

  accepts_nested_attributes_for :status, allow_destroy: true

  #
  # Validations
  #
  # NOTE:  devise :validatable above adds validations for :email and :password
  #
  validates :username, presence: true, uniqueness: true
  validates :email, confirmation: true

  validates :timezone, timezone_existence: true

  scope :admins, -> { where(admin: true) }

  scope :banned,    -> { where.not(banned_at: nil) }
  scope :active,    -> { where(banned_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  scope :by_username, ->(usernames) { iwhere(username: Array(usernames).map(&:to_s)) }

  before_validation -> { self.timezone ||= DEFAULT_TIMEZONE }

  class << self
    #
    # Devise method overridden to allow sign in with email or username
    #
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)

      return find_by(conditions) if login.nil?

      where(conditions).find_by('lower(username) = :value OR lower(email) = :value', value: login.downcase.strip)
    end

    def filter_by(filter_name)
      case filter_name.to_s
      when 'admins'
        admins
      when 'banned'
        banned
      when 'confirmed'
        confirmed
      else
        active
      end
    end

    def by_login(login)
      return nil unless login

      if login.include?('@')
        unscoped.iwhere(email: login).take
      else
        unscoped.iwhere(username: login).take
      end
    end

    # Search users with the given query
    #
    # @param query [String] - The search query as a String
    #
    # @note This method uses ILIKE on PostgreSQL
    #
    # @return [ActiveRecord::Relation]
    #
    def search(query)
      fuzzy_search(query, %i[username email])
    end
  end

  def banned?
    banned_at != nil
  end

  def active?
    !banned?
  end

  #
  # Devise method overridden to allow send emails in background
  #
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
