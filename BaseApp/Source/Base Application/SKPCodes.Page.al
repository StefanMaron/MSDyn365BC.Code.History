page 31043 "SKP Codes"
{
    Caption = 'SKP Codes';
    PageType = List;
    SourceTable = "SKP Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the standard classification of production (SKP) code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies description for classification codes.';
                }
                field("Depreciation Group"; "Depreciation Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the depreciation group name.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220004; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220002; Notes)
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

