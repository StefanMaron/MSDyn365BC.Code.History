#if CLEAN19
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
                field("Mapping Text"; "Mapping Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text on the payment that is used to map the payment to a customer, vendor, or general ledger account when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Debit Acc. No."; "Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account that payments with this text-to-account mapping are matched with when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Credit Acc. No."; "Credit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account that payments with this text-to-account mapping are applied to when you choose the Apply Automatically function in the Payment Reconciliation Journal window.';
                }
                field("Bal. Source Type"; "Bal. Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of balancing account that amounts on payments or incoming documents that have this text to account mapping are posted to. The Bank Account option is used only for incoming documents and cannot be used in payment reconciliation journals.';

                    trigger OnValidate()
                    begin
                        EnableBalSourceNo := IsBalSourceNoEnabled;
                    end;
                }
                field("Bal. Source No."; "Bal. Source No.")
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
        EnableBalSourceNo := IsBalSourceNoEnabled;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CheckEntriesAreConsistent);
    end;

    var
        EnableBalSourceNo: Boolean;
}

#endif