class Member < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  has_one :account, as: :accountable
  delegate :balance, to: :account, prefix: true, allow_nil: true
  delegate :gender, :date_of_birth, to: :user, prefix: true, allow_nil: true

  after_create :create_account
  before_validation :assign_registration_number, on: :create
  after_destroy :remove_orphaned_users

  scope :by_month, -> (month) {
    where(created_at: month.beginning_of_month..month.end_of_month)
  }
  scope :active, -> { where active: true }

  validates :organization_id, presence: true
  validates :member_uid,
            presence: true,
            uniqueness: { scope: :organization_id }

  def to_s
    "#{user}"
  end

  def assign_registration_number
    self.member_uid ||= organization.next_reg_number_seq
  end

  def days_without_swaps
    (DateTime.now.to_date - account.updated_at.to_date).to_i
  end

  def offers
    Post.where(organization: organization, user: user, type: "Offer")
  end

  private

  def remove_orphaned_users
    user.destroy if user && user.members.empty?
  end
end
