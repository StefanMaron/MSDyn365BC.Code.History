namespace Microsoft.FixedAssets.Setup;

page 5615 "FA Classes"
{
    AdditionalSearchTerms = 'fixed asset classes category';
    ApplicationArea = FixedAssets;
    Caption = 'FA Classes';
    PageType = List;
    SourceTable = "FA Class";
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
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a code for the class that the fixed asset belongs to.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the fixed asset class.';
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

