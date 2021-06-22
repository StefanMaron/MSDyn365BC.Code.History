page 5754 "Report Selection - Inventory"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Inventory';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Transfer Order,Transfer Shipment,Transfer Receipt,Inventory Period Test,Assembly Order,Posted Assembly Order,Phys. Invt. Order Test,Phys. Invt. Order,Posted Phys. Invt. Order,Phys. Invt. Recording,Posted Phys. Invt. Recording';
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
        ReportUsage2: Option "Transfer Order","Transfer Shipment","Transfer Receipt","Inventory Period Test","Assembly Order","Posted Assembly Order","Phys. Invt. Order Test","Phys. Invt. Order","Posted Phys. Invt. Order","Phys. Invt. Recording","Posted Phys. Invt. Recording";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Transfer Order":
                SetRange(Usage, Usage::Inv1);
            ReportUsage2::"Transfer Shipment":
                SetRange(Usage, Usage::Inv2);
            ReportUsage2::"Transfer Receipt":
                SetRange(Usage, Usage::Inv3);
            ReportUsage2::"Inventory Period Test":
                SetRange(Usage, Usage::"Invt.Period Test");
            ReportUsage2::"Assembly Order":
                SetRange(Usage, Usage::"Asm.Order");
            ReportUsage2::"Posted Assembly Order":
                SetRange(Usage, Usage::"P.Asm.Order");
            ReportUsage2::"Phys. Invt. Order":
                SetRange(Usage, Usage::"Phys.Invt.Order");
            ReportUsage2::"Phys. Invt. Order Test":
                SetRange(Usage, Usage::"Phys.Invt.Order Test");
            ReportUsage2::"Phys. Invt. Recording":
                SetRange(Usage, Usage::"Phys.Invt.Rec.");
            ReportUsage2::"Posted Phys. Invt. Order":
                SetRange(Usage, Usage::"P.Phys.Invt.Order");
            ReportUsage2::"Posted Phys. Invt. Recording":
                SetRange(Usage, Usage::"P.Phys.Invt.Rec.");
        end;
        FilterGroup(0);
        CurrPage.Update;
    end;
}

