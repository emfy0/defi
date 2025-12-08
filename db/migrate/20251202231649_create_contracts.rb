class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.references :lender, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :borrower, type: :uuid, null: false, foreign_key: { to_table: :users }

      t.string :state

      t.string :payment_method
      t.string :repayment_method

      t.string :currency

      t.decimal :value
      t.decimal :interest_value

      t.integer :ltv_percent
      t.integer :interest_percent

      t.decimal :initial_depopsit_volume

      t.string :lender_public_key_hex
      t.string :borrower_public_key_hex

      t.string :psbt_lender_hex
      t.string :psbt_borrower_hex
      t.string :psbt_akh_hex

      t.string :release_tx

      t.string :escrow_address
      t.string :refund_address

      t.timestamps
    end
  end
end
