page 12454 "Report Selection - Item. Docs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Item Documents';
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
                OptionCaption = 'Unposted Item Shipment,Unposted Item Receipt,Item Shipment,Item Receipt,Phys. Inventory,Item Reclassification';

                trigger OnValidate()
                begin
                    SetUsageFilter();
                    ReportUsage2OnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Default)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the report ID is the default for the report selection.';
                }
                field("Excel Export"; Rec."Excel Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the report selection will be exported.';
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

    trigger OnOpenPage()
    begin
        SetUsageFilter();
    end;

    var
        ReportUsage2: Option "Unposted Item Shipment","Unposted Item Receipt","Item Shipment","Item Receipt","Phys. Inventory","Item Reclassification";

    local procedure SetUsageFilter()
    begin
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Unposted Item Shipment":
                SetRange(Usage, Usage::"Inventory Shipment");
            ReportUsage2::"Unposted Item Receipt":
                SetRange(Usage, Usage::"Inventory Receipt");
            ReportUsage2::"Item Shipment":
                SetRange(Usage, Usage::"P.Inventory Shipment");
            ReportUsage2::"Item Receipt":
                SetRange(Usage, Usage::"P.Inventory Receipt");
            ReportUsage2::"Phys. Inventory":
                SetRange(Usage, Usage::PIJ);
            ReportUsage2::"Item Reclassification":
                SetRange(Usage, Usage::IRJ);
        end;
        FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

