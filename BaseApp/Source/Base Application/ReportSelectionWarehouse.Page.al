page 7401 "Report Selection - Warehouse"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Warehouse';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selection Warehouse";
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Put-away,Pick,Movement,Invt. Put-away,Invt. Pick,Invt. Movement,Receipt,Shipment,Posted Receipt,Posted Shipment';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option "Put-away",Pick,Movement,"Invt. Put-away","Invt. Pick","Invt. Movement",Receipt,Shipment,"Posted Receipt","Posted Shipment";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        SetRange(Usage, ReportUsage2);
        FilterGroup(0);
        CurrPage.Update;
    end;
}

