page 26101 "Report Selection - VAT"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selections VAT';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "DACH Report Selections";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ReportUsage2; ReportUsage2)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Usage';
                    OptionCaption = 'VAT Statement,Sales VAT Adv. Not. Acc. Proof,VAT Statement Schedule';
                    ToolTip = 'Specifies the report object that must run when you print.';

                    trigger OnValidate()
                    begin
                        SetUsageFilter;
                        ReportUsage2OnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where a report is in the printing order.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that prints for this document type.';
                }
                field("Report Name"; "Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the name of the report that prints for this document type.';
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

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0001Q0A', VatReportTok, Enum::"Feature Uptake Status"::Discovered);
        SetUsageFilter;
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ReportUsage2: Option "VAT Statement","Sales VAT Adv. Not. Acc. Proof","VAT Statement Schedule";
        VatReportTok: Label 'DACH VAT Report', Locked = true;

    local procedure SetUsageFilter()
    begin
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"VAT Statement":
                SetRange(Usage, Usage::"VAT Statement");
            ReportUsage2::"Sales VAT Adv. Not. Acc. Proof":
                SetRange(Usage, Usage::"Sales VAT Acc. Proof");
            ReportUsage2::"VAT Statement Schedule":
                SetRange(Usage, Usage::"VAT Statement Schedule");
        end;
        FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

