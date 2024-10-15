page 31041 "Depreciation Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Depreciation Groups';
    PageType = List;
    SourceTable = "Depreciation Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220018)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group code.';
                }
                field("Depreciation Group"; "Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group name.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group start date.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for deprecation groups.';
                }
                field("Depreciation Type"; "Depreciation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field will be regarded as part of the total depreciation for the fixed asset.';
                }
                field("No. of Depreciation Years"; "No. of Depreciation Years")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of depreciation years.';
                }
                field("No. of Depreciation Months"; "No. of Depreciation Months")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of depreciation months.';
                }
                field("Straight First Year"; "Straight First Year")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the percentage to calculate first year depreciation.';
                }
                field("Straight Next Years"; "Straight Next Years")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies percentage to calculate next year''s depreciation.';
                }
                field("Straight Appreciation"; "Straight Appreciation")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the percentage to calculate appreciation.';
                }
                field("Declining First Year"; "Declining First Year")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the multiplier to calculate first year depreciation.';
                }
                field("Declining Next Years"; "Declining Next Years")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the multiplier to calculate next year''s depreciation.';
                }
                field("Declining Appreciation"; "Declining Appreciation")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the multiplier to calculate appreciation.';
                }
                field("Declining Depr. Increase %"; "Declining Depr. Increase %")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Specifies the percentage to calculate the increase in depreciation in the first year.';
                }
                field("Min. Months After Appreciation"; "Min. Months After Appreciation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum months for appreciation.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
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

