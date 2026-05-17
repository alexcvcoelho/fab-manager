# frozen_string_literal: true

# Personal data attached to an user (like first_name, date of birth, etc.)
class Profile < ApplicationRecord
  belongs_to :user
  has_one :user_avatar, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :user_avatar,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['attachment'].blank? }

  # Whitelist for short identifying fields (names, mother's name, etc).
  # Allows unicode letters/digits, whitespace, and the punctuation actually
  # found in Brazilian names: ` ' . - , ( ) `. Explicitly rejects HTML
  # delimiters (`<`, `>`, `&`, `"`, `/`) — closes the XSS Stored vector
  # found in the 2026-05-17 pentest (item #22 in doc/security/pentest-2026-05-17.md).
  NAME_FORMAT = /\A[\p{L}\p{N}\s'.\-,()]+\z/u

  validates :first_name, presence: true, length: { maximum: 30 },
                         format: { with: NAME_FORMAT, allow_blank: true }
  validates :last_name, presence: true, length: { maximum: 30 },
                        format: { with: NAME_FORMAT, allow_blank: true }
  validates :social_name, length: { maximum: 60 },
                          format: { with: NAME_FORMAT, allow_blank: true }
  validates :mother_name, length: { maximum: 120 },
                          format: { with: NAME_FORMAT, allow_blank: true }
  validates :phone, numericality: { only_integer: true, allow_blank: false, if: -> { Setting.get('phone_required') } }

  after_commit :update_invoicing_profile, if: :invoicing_data_was_modified?
  before_validation :sanitize_attributes

  def full_name
    # if first_name or last_name is nil, the empty string will be used as a temporary replacement
    "#{(first_name || '').humanize.titleize} #{(last_name || '').humanize.titleize}"
  end

  def to_s
    full_name
  end

  def self.mapping
    # we protect some fields as they are designed to be managed by the system and must not be updated externally
    blacklist = %w[id user_id created_at updated_at]
    # model-relationships must be added manually
    additional = [%w[avatar string], %w[address string], %w[organization_name string], %w[organization_address string],
                  %w[gender boolean], %w[birthday date], %w[external_id string]]
    Profile.columns_hash
           .map { |k, v| [k, v.type.to_s] }
           .delete_if { |col| blacklist.include?(col[0]) }
           .concat(additional)
  end

  private

  # Free-form text fields that legitimately may contain newlines / basic
  # formatting but never executable HTML. Stripped of all tags before
  # validation. Closes the XSS Stored vector found in the 2026-05-17
  # pentest (item #22). Address-ish fields are included because while
  # the format is more permissive than a name, they should never carry
  # HTML either.
  TEXT_FIELDS_TO_STRIP = %i[
    interest software_mastered note website job
    street complement neighborhood
    rg rg_issuing_organization
  ].freeze

  def sanitize_attributes
    self.cpf = self.cpf.gsub(/\D/, '') if self.cpf.present?
    self.financial_responsible_cpf = self.financial_responsible_cpf.gsub(/\D/, '') if self.financial_responsible_cpf.present?
    self.zipcode = self.zipcode.gsub(/\D/, '') if self.zipcode.present?

    sanitizer = ActionController::Base.helpers
    TEXT_FIELDS_TO_STRIP.each do |attr|
      next unless respond_to?(attr) && self[attr].present?

      self[attr] = sanitizer.strip_tags(self[attr])
    end
  end

  def invoicing_data_was_modified?
    saved_change_to_first_name? || saved_change_to_last_name? || new_record?
  end

  def update_invoicing_profile
    raise NoProfileError if user.invoicing_profile.nil?

    user.invoicing_profile.update(
      first_name: first_name,
      last_name: last_name
    )
  end
end
