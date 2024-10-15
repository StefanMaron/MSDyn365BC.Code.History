#if not CLEAN19
page 1251 "Text-to-Account Mapping"
{
    AutoSplitKey = true;
    Caption = 'Text-to-Account Mapping';
    PageType = List;
    SaveValues = true;
    SourceTable = "Text-to-Account Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Mapping Text"; Rec."Mapping Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text on the payment that is used to map the payment to a customer, vendor, or general ledger account when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Variable Symbol"; Rec."Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Specific Symbol"; Rec."Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Constant Symbol"; Rec."Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of bank account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Bank Transaction Type"; Rec."Bank Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the bank transaction';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if customer bank account is a priority customer bank account';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description of the mapping line';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Debit Acc. No."; Rec."Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account that payments with this text-to-account mapping are matched with when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Credit Acc. No."; Rec."Credit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account that payments with this text-to-account mapping are applied to when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Bal. Source Type"; Rec."Bal. Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of balancing account that amounts on payments or incoming documents that have this text to account mapping are posted to. The Bank Account option is used only for incoming documents and cannot be used in payment reconciliation journals.';

                    trigger OnValidate()
                    begin
                        EnableBalSourceNo := IsBalSourceNoEnabled();
                    end;
                }
                field("Bal. Source No."; Rec."Bal. Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = EnableBalSourceNo;
                    ToolTip = 'Specifies the balancing account to post amounts on payments or incoming documents that have this text to account mapping. The Bank Account option in the Bal. Source Type cannot be used in payment reconciliation journals.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableBalSourceNo := IsBalSourceNoEnabled();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CheckEntriesAreConsistent());
    end;

    var
        EnableBalSourceNo: Boolean;
}

#endif