page 5660 "Depreciation Table Lines"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Depreciation Table Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the depreciation period that this line applies to.';
                }
                field("Period Depreciation %"; Rec."Period Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the depreciation percentage to apply to the period for this line.';
                }
                field("No. of Units in Period"; Rec."No. of Units in Period")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the units produced by the asset this depreciation table applies to, during the period when this line applies.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord();
    end;
}

