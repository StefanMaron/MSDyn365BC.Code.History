page 5932 "Report Selection - Service"
{
    ApplicationArea = Service;
    Caption = 'Report Selection - Service';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Service;
                Caption = 'Usage';
                OptionCaption = 'Quote,Order,Invoice,Credit Memo,Contract Quote,Contract,Service Document - Test,Shipment';
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
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the sequence number for the report.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Service;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Service;
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
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option Quote,"Order",Invoice,"Credit Memo","Contract Quote",Contract,"Service Document - Test",Shipment;

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                SetRange(Usage, Usage::"SM.Quote");
            ReportUsage2::Order:
                SetRange(Usage, Usage::"SM.Order");
            ReportUsage2::Shipment:
                SetRange(Usage, Usage::"SM.Shipment");
            ReportUsage2::Invoice:
                SetRange(Usage, Usage::"SM.Invoice");
            ReportUsage2::"Credit Memo":
                SetRange(Usage, Usage::"SM.Credit Memo");
            ReportUsage2::"Contract Quote":
                SetRange(Usage, Usage::"SM.Contract Quote");
            ReportUsage2::Contract:
                SetRange(Usage, Usage::"SM.Contract");
            ReportUsage2::"Service Document - Test":
                SetRange(Usage, Usage::"SM.Test");
        end;
        FilterGroup(0);
        CurrPage.Update;
    end;

    local procedure InitUsageFilter()
    var
        DummyReportSelections: Record "Report Selections";
    begin
        if GetFilter(Usage) <> '' then begin
            if Evaluate(DummyReportSelections.Usage, GetFilter(Usage)) then
                case DummyReportSelections.Usage of
                    Usage::"SM.Quote":
                        ReportUsage2 := ReportUsage2::Quote;
                    Usage::"SM.Order":
                        ReportUsage2 := ReportUsage2::Order;
                    Usage::"SM.Shipment":
                        ReportUsage2 := ReportUsage2::Shipment;
                    Usage::"SM.Invoice":
                        ReportUsage2 := ReportUsage2::Invoice;
                    Usage::"SM.Credit Memo":
                        ReportUsage2 := ReportUsage2::"Credit Memo";
                    Usage::"SM.Contract Quote":
                        ReportUsage2 := ReportUsage2::"Contract Quote";
                    Usage::"SM.Contract":
                        ReportUsage2 := ReportUsage2::Contract;
                    Usage::"SM.Test":
                        ReportUsage2 := ReportUsage2::"Service Document - Test";
                end;
            SetRange(Usage);
        end;
    end;
}

