namespace Microsoft.Service.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

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
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the sequence number for the report.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Service;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related document will be attached to the email.';
                }
                field(EmailBodyName; Rec."Email Body Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the email body layout that is used.';
                }
                field(EmailBodyPublisher; Rec."Email Body Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the publisher of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body custom layout that is used.';
                    Visible = CustomLayoutsExist;

                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK(Rec."Report ID") then
                            Rec.Validate("Email Body Layout Code", CustomReportLayout.Code);
                    end;
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
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
        CustomLayoutsExist := Rec.DoesAnyCustomLayotExist();
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Service";
        CustomLayoutsExist: Boolean;

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                Rec.SetRange(Usage, Rec.Usage::"SM.Quote");
            ReportUsage2::Order:
                Rec.SetRange(Usage, Rec.Usage::"SM.Order");
            ReportUsage2::Shipment:
                Rec.SetRange(Usage, Rec.Usage::"SM.Shipment");
            ReportUsage2::Invoice:
                Rec.SetRange(Usage, Rec.Usage::"SM.Invoice");
            ReportUsage2::"Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::"SM.Credit Memo");
            ReportUsage2::"Contract Quote":
                Rec.SetRange(Usage, Rec.Usage::"SM.Contract Quote");
            ReportUsage2::Contract:
                Rec.SetRange(Usage, Rec.Usage::"SM.Contract");
            ReportUsage2::"Service Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"SM.Test");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        ReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(ReportUsage, Rec.GetFilter(Usage)) then
                case ReportUsage of
                    ReportUsage::"SM.Quote":
                        ReportUsage2 := ReportUsage2::Quote;
                    ReportUsage::"SM.Order":
                        ReportUsage2 := ReportUsage2::Order;
                    ReportUsage::"SM.Shipment":
                        ReportUsage2 := ReportUsage2::Shipment;
                    ReportUsage::"SM.Invoice":
                        ReportUsage2 := ReportUsage2::Invoice;
                    ReportUsage::"SM.Credit Memo":
                        ReportUsage2 := ReportUsage2::"Credit Memo";
                    ReportUsage::"SM.Contract Quote":
                        ReportUsage2 := ReportUsage2::"Contract Quote";
                    ReportUsage::"SM.Contract":
                        ReportUsage2 := ReportUsage2::Contract;
                    ReportUsage::"SM.Test":
                        ReportUsage2 := ReportUsage2::"Service Document - Test";
                    else
                        OnInitUsageFilterOnElseCase(ReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Service")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Service")
    begin
    end;
}
