page 26100 "Report Selection - Intrastat"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection';
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
                    OptionCaption = 'Checklist Report,Form,Make Disk Tax Auth.,Disklabel';
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
        SetUsageFilter;
    end;

    var
        ReportUsage2: Option Checklist,Form,Disk,Disklabel;

    local procedure SetUsageFilter()
    begin
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Checklist:
                SetRange(Usage, Usage::"Intrastat Checklist");
            ReportUsage2::Form:
                SetRange(Usage, Usage::"Intrastat Form");
            ReportUsage2::Disk:
                SetRange(Usage, Usage::"Intrastat Disk");
            ReportUsage2::Disklabel:
                SetRange(Usage, Usage::"Intrastat Disklabel");
        end;
        FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

