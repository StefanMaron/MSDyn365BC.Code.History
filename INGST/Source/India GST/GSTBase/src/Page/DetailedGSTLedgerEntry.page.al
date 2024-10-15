page 18000 "Detailed GST Ledger Entry"
{
    Caption = 'Detailed GST Ledger Entry';
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Detailed GST Ledger Entry";


    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry is an initial entry or an application entry or an adjustment entry.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the transaction is a sale or purchase.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the document type is Payment, Invoice, Credit Memo, Transfer or Refund.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the transaction that created the entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the detailed  GST ledger entry.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the type is G/L Account, Item, Resource, Fixed Asset or Charge (Item).';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Item No., G/L Account No. etc.';
                }
                field("Product Type"; Rec."Product Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the type is G/L Account, Item, Resource, Fixed Asset or Charge (Item).';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Source Type as customer for sales transaction,. For purchase transaction, Source Type is vendor. For Bank Charges Transaction, Source Type is Bank account.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor number, if Source Type is vendor. If Source Type is customer, then the customer number is displayed. If Source Type is Bank Account, the Bank Account No. is displayed.';
                }
                field("HSN/SAC Code"; Rec."HSN/SAC Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the HSN for Items & Fixed Assets. SAC for Services & Resources. For charges, it can be either SAC or HSN.';
                }
                field("GST Component Code"; Rec."GST Component Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST component code with which the entry was posted.';
                }
                field("GST Group Code"; Rec."GST Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the GST Group code of the transaction.';
                }
                field("GST Jurisdiction Type"; Rec."GST Jurisdiction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type related to GST jurisdiction. For example, interstate/intrastate.';
                }
                field("GST Base Amount"; Rec."GST Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the base amount on which GST percentage is applied.';
                }
                field("GST Amount"; Rec."GST Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the tax amount computed by applying GST percentage on GST base.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the external document number entered in the purchase/sales document/journal bank charges Line.';
                }
                field("Amount Loaded on Item"; Rec."Amount Loaded on Item")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the charges or tax amount loaded on the line item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity.';
                }
                field(Paid; Rec.Paid)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether GST has been paid to the government through GST settlement.';
                }
                field("GST Without Payment of Duty"; Rec."GST Without Payment of Duty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction is made with or without payment of duty.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This displays the general ledger account of tax component.';
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies reversal entry number. Transactions posted through journals can be reversed.';
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the transaction has been reversed or not.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who posted the transaction.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the amount in the line is positive or not.';
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document line number.';
                }
                field("Item Charge Entry"; Rec."Item Charge Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry is an Item charge entry.';
                }
                field("Reverse Charge"; Rec."Reverse Charge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the reverse charge is applicable for this GST group or not.';
                }
                field("GST on Advance Payment"; Rec."GST on Advance Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if GST is required to be calculated on Advance Payment.';
                }
                field("Nature of Supply"; Rec."Nature of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the nature of GST transaction. For example, B2B/B2C.';
                }
                field("Payment Document No."; Rec."Payment Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement document number  when GST is paid through GST settlement.';
                }
                field("GST Exempted Goods"; Rec."GST Exempted Goods")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the goods/services are exempted from GST.';
                }
                field("GST %"; Rec."GST %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST % on the GST ledger entry.';
                }
                field("Location State Code"; Rec."Location State Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state code of location.';
                }
                field("Buyer/Seller State Code"; Rec."Buyer/Seller State Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer/vendor state code.';
                }
                field("Shipping Address State Code"; Rec."Shipping Address State Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state code for the shipping address.';
                }
                field("Location  Reg. No."; Rec."Location  Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GSTIN of location.';
                }
                field("Buyer/Seller Reg. No."; "Buyer/Seller Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer/vendor GST Registration number.';
                }
                field("GST Group Type"; "GST Group Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the GST group is assigned for goods or service.';
                }
                field("GST Credit"; "GST Credit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the GST credit has to be availed or not.';
                }
                field("Adv. Pmt. Adjustment"; "Adv. Pmt. Adjustment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when an adjustment is made to a posted advance payment.';
                }
                field("Original Adv. Pmt Doc. No."; "Original Adv. Pmt Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original advance payment document number if the same is adjusted.';
                }
                field("Original Adv. Pmt Doc. Date"; "Original Adv. Pmt Doc. Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original advance payment document date.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code on GST ledger entry.';
                }
                field("GST Rounding Precision"; "GST Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST Rounding precesion for the GST Ledger Entry';
                }
                field("GST Rounding Type"; "GST Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST Rounding type for the GST Ledger Entry';
                }
                field("GST Customer Type"; "GST Customer Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the customer. For example, Registered, Unregistered, Export etc..';
                }
                field("GST Vendor Type"; "GST Vendor Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the vendor. For example,  Registered, Unregistered, Composite, Import etc..';
                }
                field("Original Invoice Date"; "Original Invoice Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Original invoice date of the GST ledger entry.';
                }
                field("Bill Of Export No."; "Bill Of Export No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill of export number. It is a document number which is submitted to custom department .';
                }
                field("Bill Of Export Date"; "Bill Of Export Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date defined in bill of export document.';
                }
                field("e-Comm. Merchant Id"; "e-Comm. Merchant Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the merchant ID given by the e-commerce operator.';
                }
                field("e-Comm. Operator GST Reg. No."; "e-Comm. Operator GST Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of an e-commerce operator.';
                }
                field("Sales Invoice Type"; "Sales Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice type of the sales transaction.';
                }
                field("Purchase Invoice Type"; "Purchase Invoice Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice type of the purchase transaction.';
                }
                field("Original Invoice No."; "Original Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Original invoice number on the GST ledger entry.';
                }
                field("Payment Document Date"; "Payment Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement posting date when GST is paid through GST settlement.';
                }
                field("Credit Reversal"; "Credit Reversal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Credit reversal.';
                }
                field("Reconciliation Month"; "Reconciliation Month")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year in which the transaction is reconciled through GST Reconciliation feature.';
                }
                field("Reconciliation Year"; "Reconciliation Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year in which the transaction is reconciled through GST Reconciliation feature.';
                }
                field(Reconciled; Reconciled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction has been reconciled.';
                }
                field("Credit Adjustment Type"; "Credit Adjustment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of credit adjustment. For example, credit reversal, credit re-availment etc.';
                }
                field("Credit Availed"; "Credit Availed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the GST credit has been availed or not.';
                }
                field("Liable to Pay"; "Liable to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the payment liability occurs  for the transaction or not.';
                }
                field("Payment Type"; "Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of payment.';
                }
                field("Component Calc. Type"; "Component Calc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Component Calc. Type for the ledger Entry.';
                }
                field("Cess Amount Per Unit Factor"; "Cess Amount Per Unit Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Cess Amount per Unit Factor for the ledger entry.';
                }
                field("Cess UOM"; "Cess UOM")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Cess Unit of Measure for the ledger entry.';
                }
                field("Cess Factor Quantity"; "Cess Factor Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Cess Factor Quantity for the ledger entry.';
                }
                field("Bill of Entry No."; "Bill of Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill of entry number. It is a document number which is submitted to custom department.';
                }
                field("Bill of Entry Date"; "Bill of Entry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Bill of entry date on the GST ledger entry.';
                }
                field("Eligibility for ITC"; "Eligibility for ITC")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Eligibility for ITC on the GST ledger entry.';
                }
                field("GST Assessable Value"; "GST Assessable Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST assessable value on the GST ledger entry.';
                }
                field("Custom Duty Amount"; "Custom Duty Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Custom duty amount on the GST ledger entry.';
                }
                field("Foreign Exchange"; "Foreign Exchange")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether it is a foreign currency transaction or not.';
                }
                field("Bank Charge Entry"; "Bank Charge Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry is a bank charge transaction.';
                }
                field("Jnl. Bank Charge"; "Jnl. Bank Charge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank charge code.';
                }
                field("RCM Exempt"; "RCM Exempt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the RCM exempt on the GST ledger entry.';
                }
                field("Cr. & Libty. Adjustment Type"; "Cr. & Libty. Adjustment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit and liability adjustment type for the ledger entry.';
                }
                field("Bill to-Location(POS)"; "Bill to-Location(POS)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the billing location for the ledger entry.';
                }
                field("Journal Entry"; "Journal Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction is posted from Journal with document type Invoice or Credit Memo.';
                }
                field("ARN No."; "ARN No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Customer/Vendor ARN number.';
                }
                field("FA Journal Entry"; "FA Journal Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction is posted from FA Journal.';
                }
                field("Without Bill Of Entry"; "Without Bill Of Entry")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the ledger entry is created with or without Bill of entry.';
                }
                field("Finance Charge Memo"; "Finance Charge Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Finance charge memo on the ledger entry.';
                }
                field("Forex Fluctuation"; "Forex Fluctuation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Forex fluctuation on the ledger entry.';
                }
                field("CAJ %"; "CAJ %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the CAJ % which is updated from credit adjustment journal line.';
                }
                field("CAJ Amount"; "CAJ Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the CAJ amount which is updated from credit adjustment journal line, displays the adjusted GST amount.';
                }
                field("CAJ % Permanent Reversal"; "CAJ % Permanent Reversal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the CAJ % of payment reversal which is updated from credit adjustment journal line if Adjustment Type is selected as Permanent Reversal. ';
                }
                field("CAJ Amount Permanent Reversal"; "CAJ Amount Permanent Reversal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of permanent reversal which is  updated from credit adjustment journal line, displays the GST amount for Adjustment Type - Permanent Reversal.';
                }
                field("Location ARN No."; "Location ARN No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location ARN number.';
                }
                field("Rate Change Applicable"; "Rate Change Applicable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rate change applicable on the GST ledger entry.';
                }
                field("Remaining CAJ Adj. Base Amt"; "Remaining CAJ Adj. Base Amt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining GST base amount after posting adjustments which is updated on posting credit adjustment journal. ';
                }
                field("Remaining CAJ Adj. Amt"; "Remaining CAJ Adj. Amt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining GST amount after posting adjustments which is updated on posting credit adjustment journal. ';
                }
                field("POS as Vendor State"; "POS as Vendor State")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the POS as vendor state on the GST ledger entry.';
                }
                field("POS Out Of India"; "POS Out Of India")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the POS out of India on the GST ledger entry.';
                }
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number that the Detailed GST entry belongs to.';
                }
                field("GST Base Amount FCY"; "GST Base Amount FCY")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the tax amount computed by applying GST percentage on GST base in foreign currency';
                }
                field("GST Amount FCY"; "GST Amount FCY")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Displays the tax amount in foreign currency, computed by applying GST percentage on GST base.';
                }
                field("Currency Factor"; "Currency Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies currency factor for this transactions.';
                }
                field("GST Place of Supply"; "GST Place of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the GST Place of Supply. For example Bill-to Address, Ship-to Address, Location Address etc.';
                }
            }
        }
    }




}

