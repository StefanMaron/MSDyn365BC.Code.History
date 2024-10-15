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
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("Invoices to Cartera"; Rec."Invoices to Cartera")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a check mark in this field to send the invoices to Portfolio for this specific payment method.';
                }
                field("Create Bills"; Rec."Create Bills")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a check mark so that this payment method creates bills.';
                }
                field("Bill Type"; Rec."Bill Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that originated from this specific payment method.';
                }
                field("Collection Agent"; Rec."Collection Agent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the collection agent to which you will deliver the document that originated from this specific payment method.';
                }
                field("Submit for Acceptance"; Rec."Submit for Acceptance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a check mark in this field if the bill must be sent to the customer for acceptance first.';
                }
                field("Direct Debit"; Rec."Direct Debit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the payment method is used for direct debit collection.';
                }
                field("Direct Debit Pmt. Terms Code"; Rec."Direct Debit Pmt. Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment terms that will be used when the payment method is used for direct debit collection.';
                }
                field("Pmt. Export Line Definition"; Rec."Pmt. Export Line Definition")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange definition in the Data Exchange Framework that is used to export payments.';
                }
#if not CLEAN21
                field("Use for Invoicing"; Rec."Use for Invoicing")
                {
                    ApplicationArea = Invoicing;
                    ToolTip = 'Specifies whether or not payment term is used for Invoicing app.';
                    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '21.0';
                }
#endif
                field("SII Payment Method Code"; Rec."SII Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the sii:Medio node in the SII XML file.';
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
                RunObject = Page "Payment Method Translations";
                RunPageLink = "Payment Method Code" = FIELD(Code);
                ToolTip = 'View or edit descriptions for each payment method in different languages.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("T&ranslation_Promoted"; "T&ranslation")
                {
                }
            }
        }
    }
}

