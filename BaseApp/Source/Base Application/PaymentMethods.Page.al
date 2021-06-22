page 427 "Payment Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Methods';
    PageType = List;
    SourceTable = "Payment Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this payment method.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a text that describes the payment method.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("Direct Debit"; "Direct Debit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the payment method is used for direct debit collection.';
                }
                field("Direct Debit Pmt. Terms Code"; "Direct Debit Pmt. Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment terms that will be used when the payment method is used for direct debit collection.';
                }
                field("Pmt. Export Line Definition"; "Pmt. Export Line Definition")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange definition in the Data Exchange Framework that is used to export payments.';
                }
                field("Use for Invoicing"; "Use for Invoicing")
                {
                    ApplicationArea = Invoicing;
                    ToolTip = 'Specifies whether or not payment term is used for Invoicing app.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payment Method Translations";
                RunPageLink = "Payment Method Code" = FIELD(Code);
                ToolTip = 'View or edit descriptions for each payment method in different languages.';
            }
        }
    }
}

