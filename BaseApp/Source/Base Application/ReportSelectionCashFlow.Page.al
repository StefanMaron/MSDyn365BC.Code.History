page 865 "Report Selection - Cash Flow"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Cash Flow';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Cash Flow Report Selection";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1002)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;
}

