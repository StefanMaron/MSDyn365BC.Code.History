#if not CLEAN18
page 31040 "Classification Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Classification Codes (Obsolete)';
    PageType = List;
    SourceTable = "Classification Code";
    SourceTableView = SORTING("Classification Type", Code);
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220007)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the classification code for fixed asset.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for classification groups.';
                }
                field("Classification Type"; "Classification Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the classification code. You can insert code with classification type CZ-CC, CZ-CPA or DNM.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
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
#endif
