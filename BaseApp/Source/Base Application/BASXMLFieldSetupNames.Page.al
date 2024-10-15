page 11612 "BAS XML Field Setup Names"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS XML Field Setup Names';
    PageType = List;
    SourceTable = "BAS XML Field Setup Name";
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
                    ToolTip = 'Specifies the extensible markup language (XML) field setup name for the business activity statement (BAS).';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the extensible markup language (XML) field setup name for the business activity statement (BAS).';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&BAS XML Field ID Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&BAS XML Field ID Setup';
                Image = XMLSetup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BAS - XML Field IDs Setup";
                RunPageLink = "Setup Name" = FIELD(Name);
                ToolTip = 'View the business activity statement (BAS) extensible markup language (XML) fields from the Australian Taxation Office (ATO). ';
            }
            action("BAS - XML Field IDs Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'BAS - XML Field IDs Setup';
                Image = SetupList;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "BAS - XML Field IDs Setup";
                ToolTip = 'Open the list of business activity statement (BAS) extensible markup language (XML) fields from the Australian Taxation Office (ATO).';
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

