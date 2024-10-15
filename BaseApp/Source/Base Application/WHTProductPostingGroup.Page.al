page 28041 "WHT Product Posting Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Product Posting Group';
    PageType = List;
    SourceTable = "WHT Product Posting Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for the posting group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the WHT Product posting group.';
                }
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
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "WHT Posting Setup";
                RunPageLink = "WHT Product Posting Group" = FIELD(Code);
                ToolTip = 'View or edit the withholding tax (WHT) posting setup information. This includes posting groups, revenue types, and accounts.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000HH3', APACWHTTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        APACWHTTok: Label 'APAC Set Up Withholding Tax', Locked = true;
}

