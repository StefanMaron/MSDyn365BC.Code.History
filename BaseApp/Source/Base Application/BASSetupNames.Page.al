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
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a name according to the requirements for setting up the BAS configuration rules.';
                }
                field(Description; Description)
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
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BAS Setup";
                RunPageLink = "Setup Name" = FIELD(Name);
                ToolTip = 'View the business activity statement (BAS) configuration information.';
            }
        }
        area(creation)
        {
            action("BAS Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'BAS Setup';
                Image = VATStatement;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = New;
                RunObject = Page "BAS Setup";
                RunPageMode = Create;
                ToolTip = 'View or edit the business activity statement (BAS) configuration information.';
            }
        }
    }

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        GLSetup.TestField("Enable GST (Australia)", true);
    end;
}

