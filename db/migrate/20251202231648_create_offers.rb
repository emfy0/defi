class CreateOffers < ActiveRecord::Migration[8.0]
  def change
    create_table :offers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :payment_method

      t.decimal :value
      t.integer :ltv_percent
      t.integer :interest_percent

      t.timestamps
    end
  end
end
