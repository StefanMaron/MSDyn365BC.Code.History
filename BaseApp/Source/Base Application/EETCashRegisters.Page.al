page 31122 "EET Cash Registers"
{
    Caption = 'EET Cash Registers';
    DataCaptionFields = "Business Premises Code";
    PageType = List;
    SourceTable = "EET Cash Register";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Business Premises Code"; "Business Premises Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the premises.';
                    Visible = false;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the cash register.';
                }
                field("Register Type"; "Register Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the cash register.';
                }
                field("Register No."; "Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash bank account.';
                }
                field("Register Name"; "Register Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the cash register.';
                }
                field("Certificate Code"; "Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the certificate needed to register sales.';
                }
                field("Receipt Serial Nos."; "Receipt Serial Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for the receipt serial numbers.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("EET Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'EET Entries';
                    Image = LedgerEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "EET Entries";
                    RunPageLink = "Business Premises Code" = FIELD("Business Premises Code"),
                                  "Cash Register Code" = FIELD(Code);
                    RunPageView = SORTING("Business Premises Code", "Cash Register Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Displays a list of EET entries for the selected cash register.';
                }
            }
        }
    }
}

