page 11742 "Cash Desk Events Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Desk Events Setup';
    PageType = List;
    SourceTable = "Cash Desk Event";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220015)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies code of cash desk events.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description of cash desk events.';
                }
                field("Cash Desk No."; "Cash Desk No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies cash desk events which can the user use for defined cash desk.';
                }
                field("Cash Document Type"; "Cash Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the cash desk document represents a cash receipt (Receipt) or a withdrawal (Wirthdrawal)';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account thet the entry will be posted to. To see the options, choose the field.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies default document type for selected cash desk events.';
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies general posting type for selected cash desk events (purchase, sales).';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group code.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code associated with the cash desk.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value code associated with the cash desk.';
                }
                field("EET Transaction"; "EET Transaction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that cash desk event is designed to record sales (EET).';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cash Desk Events")
            {
                Caption = '&Cash Desk Events';
                action("Default Dimension")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Dimension';
                    Image = DefaultDimension;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(11741),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'Open the page for default dimension of cash desk events setup.';
                }
            }
        }
    }
}

