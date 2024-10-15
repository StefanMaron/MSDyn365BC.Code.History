page 11608 "BAS Setup Names"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS Setup Names';
    PageType = List;
    SourceTable = "BAS Setup Name";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a name according to the requirements for setting up the BAS configuration rules.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the descriptive term for the Business Activity Statement (BAS) Name.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&BAS Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&BAS Setup';
                Image = VATStatement;
                RunObject = Page "BAS Setup";
                RunPageLink = "Setup Name" = FIELD(Name);
                ToolTip = 'View the business activity statement (BAS) configuration information.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&BAS Setup_Promoted"; "&BAS Setup")
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;
}

