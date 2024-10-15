page 15000004 "Remittance Account Card"
{
    Caption = 'Remittance Account Card';
    PageType = Card;
    SourceTable = "Remittance Account";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the remittance account.';
                }
                field("Remittance Agreement Code"; "Remittance Agreement Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remittance agreement.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment type.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the remittance account.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account.';
                }
                field("BBS Agreement ID"; "BBS Agreement ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement with BBS.';
                }
            }
            group(Finance)
            {
                Caption = 'Finance';
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that if Account Type is set to Finance, then the Account No. field specifies the general ledger account for the transaction.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that if Account Type is set to Finance, then the Account No. field specifies the general ledger account for the transaction.';
                }
                field("Charge Account No."; "Charge Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the charge account.';
                }
                field("Round off/Divergence Acc. No."; "Round off/Divergence Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for rounding differences between currencies.';
                }
                field("Max. Round off/Diverg. (LCY)"; "Max. Round off/Diverg. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum rounding difference for this remittance account.';
                }
                field("Document No. Series"; "Document No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for the payment documents.';
                }
                field("New Document Per."; "New Document Per.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how documents are numbered when payments are posted.';
                }
                field("Return Journal Template Name"; "Return Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general journal template that settled payments are transferred to.';
                }
                field("Return Journal Name"; "Return Journal Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general journal batch that settled payments are transferred to.';
                }
            }
            group(Domestic)
            {
                Caption = 'Domestic';
                field("Recipient ref. 1 - Invoice"; "Recipient ref. 1 - Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
                field("Recipient ref. 2 - Invoice"; "Recipient ref. 2 - Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
                field("Recipient ref. 3 - Invoice"; "Recipient ref. 3 - Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
                field("Recipient ref. 1 - Cr. Memo"; "Recipient ref. 1 - Cr. Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
                field("Recipient ref. 2 - Cr. Memo"; "Recipient ref. 2 - Cr. Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
                field("Recipient ref. 3 - Cr. Memo"; "Recipient ref. 3 - Cr. Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
            }
            group(Foreign)
            {
                Caption = 'Foreign';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the payment.';
                }
                field("Recipient Ref. Abroad"; "Recipient Ref. Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies template text that displays on the vendor card.';
                }
                field("Futures Contract No."; "Futures Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the futures contract if this transaction is linked to a futures contract.';
                }
                field("Futures Contract Exch. Rate"; "Futures Contract Exch. Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exchange rate of the futures contract if this transaction is linked to a futures contract.';
                }
            }
        }
    }

    actions
    {
    }
}

