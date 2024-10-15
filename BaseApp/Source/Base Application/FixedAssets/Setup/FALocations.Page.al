namespace Microsoft.FixedAssets.Setup;

page 5617 "FA Locations"
{
    AdditionalSearchTerms = 'fixed asset locations departments sites offices';
    ApplicationArea = FixedAssets;
    Caption = 'FA Locations';
    PageType = List;
    SourceTable = "FA Location";
    UsageCategory = Administration;
    AnalysisModeEnabled = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a location code for the fixed asset.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the fixed asset location.';
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
    }
}

