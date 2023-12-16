class AddFirjanFieldsToProfile < ActiveRecord::Migration[7.0]
  def change
    add_column :profiles, :social_name, :string
    add_column :profiles, :origin_state, :string
    add_column :profiles, :origin_city, :string
    add_column :profiles, :zipcode, :string
    add_column :profiles, :street, :string
    add_column :profiles, :neighborhood, :string
    add_column :profiles, :number, :integer
    add_column :profiles, :complement, :string
    add_column :profiles, :city, :string
    add_column :profiles, :state, :string
    add_column :profiles, :rg, :string
    add_column :profiles, :rg_date_emission, :date
    add_column :profiles, :rg_issuing_organization, :string
    add_column :profiles, :rg_issuing_state, :string
    add_column :profiles, :mother_name, :string
    add_column :profiles, :occupational_status, :string
    add_column :profiles, :education_level, :string
    add_column :profiles, :financial_responsible_name, :string
    add_column :profiles, :financial_responsible_cpf, :string
  end
end
