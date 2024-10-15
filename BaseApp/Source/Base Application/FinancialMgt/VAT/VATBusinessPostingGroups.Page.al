page 470 "VAT Business Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Business Posting Groups';
    PageType = List;
    SourceTable = "VAT Business Posting Group";
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
                    ToolTip = 'Specifies a code for the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
                }
                field("Default Sales Operation Type"; Rec."Default Sales Operation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default operation type that is used for sales transactions.';
                }
                field("Default Purch. Operation Type"; Rec."Default Purch. Operation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default operation type that is used for purchase transactions.';
                }
                field("Check VAT Exemption"; Rec."Check VAT Exemption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT posting group applies to a VAT exemption.';
                    Visible = false;
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
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "VAT Posting Setup";
                RunPageLink = "VAT Bus. Posting Group" = FIELD(Code);
                ToolTip = 'View or edit combinations of Tax business posting groups and Tax product posting groups. Fill in a line for each combination of VAT business posting group and VAT product posting group.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
            }
        }
    }
}

