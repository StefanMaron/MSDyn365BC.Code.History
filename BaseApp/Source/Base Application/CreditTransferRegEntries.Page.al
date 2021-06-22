page 1206 "Credit Transfer Reg. Entries"
{
    Caption = 'Credit Transfer Reg. Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Credit Transfer Entry";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that received payment with the credit transfer. If the type is Debitor, then the credit transfer was a refund.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor, or debitor, who received payment with the credit transfer. If the Account Type field contains Debitor, then the credit transfer was a refund.';
                }
                field("Applies-to Entry No."; "Applies-to Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the purchase invoice that the vendor ledger entry behind this credit transfer was applied to.';
                }
                field("Transfer Date"; "Transfer Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the SEPA credit transfer is made. The value is copied from the Posting Date field on the payment line for the purchase invoice.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that the SEPA credit transfer was made in. To process payments using SEPA Credit Transfer, the currency on the purchase invoice must be EURO.';
                }
                field("Transfer Amount"; "Transfer Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is paid with the SEPA credit transfer.';
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the exported payment file for this credit transfer register entry has been canceled.';
                }
                field("Transaction ID"; "Transaction ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the credit transfer. The ID is defined from the value in the Identifier field in the Credit Transfer Register field plus the value in the Entry No. field, divided by a slash. For example, DABA00113/3.';
                }
                field(CreditorName; CreditorName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recipient Name';
                    ToolTip = 'Specifies the recipient of the exported credit transfer, typically a vendor.';
                }
                field(RecipientIBAN; GetRecipientIBANOrBankAccNo(true))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recipient IBAN';
                    ToolTip = 'Specifies the IBAN of the creditor bank account that was used on the payment journal line that this credit transfer file was exported from.';
                }
                field("GetRecipientIBANOrBankAccNo(FALSE)"; GetRecipientIBANOrBankAccNo(false))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recipient Bank Acc. No.';
                    ToolTip = 'Specifies the number of the creditor bank account that was used on the payment journal line that this credit transfer file was exported from.';
                }
                field("Message to Recipient"; "Message to Recipient")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Message to Recipient';
                    ToolTip = 'Specifies the text that was entered in the Message to Recipient field on the payment journal line that this credit transfer file was exported from.';
                }
                field(AppliesToEntryDocumentNo; AppliesToEntryDocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Document No.';
                    ToolTip = 'Specifies the entry number of the purchase invoice that the vendor ledger entry behind this credit transfer was applied to.';
                }
                field(AppliesToEntryPostingDate; AppliesToEntryPostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Posting Date';
                    ToolTip = 'Specifies when the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to was posted.';
                }
                field(AppliesToEntryDescription; AppliesToEntryDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Description';
                    ToolTip = 'Specifies the description of the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field(AppliesToEntryCurrencyCode; AppliesToEntryCurrencyCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'Applies-to Entry Currency Code';
                    ToolTip = 'Specifies the currency of the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field(AppliesToEntryAmount; AppliesToEntryAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Amount';
                    ToolTip = 'Specifies the payment amount on the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field(AppliesToEntryRemainingAmount; AppliesToEntryRemainingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Entry Remaining Amount';
                    ToolTip = 'Specifies the amount that remains to be paid on the purchase invoice that the vendor ledger entry behind this credit transfer entry applies to.';
                }
                field("Credit Transfer Register No."; "Credit Transfer Register No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the credit-transfer register entry in the Credit Transfer Registers window that the credit transfer entry relates to.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

