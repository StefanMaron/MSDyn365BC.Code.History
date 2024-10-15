namespace Microsoft.Sales.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 306 "Report Selection - Sales"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Sales';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                FreezeColumn = "Report Caption";
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
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
                    ToolTip = 'Specifies the ID of the custom email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the custom email body layout that is used.';
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
        ReportUsage2: Enum "Report Selection Usage Sales";
        CustomLayoutsExist: Boolean;

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            Enum::"Report Selection Usage Sales"::Quote:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Quote");
            Enum::"Report Selection Usage Sales"::"Blanket Order":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Blanket");
            Enum::"Report Selection Usage Sales"::Order:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Order");
            Enum::"Report Selection Usage Sales"::"Work Order":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Work Order");
            Enum::"Report Selection Usage Sales"::"Pick Instruction":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Order Pick Instruction");
            Enum::"Report Selection Usage Sales"::Invoice:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Invoice");
            Enum::"Report Selection Usage Sales"::"Draft Invoice":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Invoice Draft");
            Enum::"Report Selection Usage Sales"::"Return Order":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Return");
            Enum::"Report Selection Usage Sales"::"Credit Memo":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Cr.Memo");
            Enum::"Report Selection Usage Sales"::Shipment:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Shipment");
            Enum::"Report Selection Usage Sales"::"Return Receipt":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Ret.Rcpt.");
            Enum::"Report Selection Usage Sales"::"Sales Document - Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Test");
            Enum::"Report Selection Usage Sales"::"Prepayment Document - Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Test Prepmt.");
            Enum::"Report Selection Usage Sales"::"Archived Quote":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Arch.Quote");
            Enum::"Report Selection Usage Sales"::"Archived Order":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Arch.Order");
            Enum::"Report Selection Usage Sales"::"Archived Return Order":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Arch.Return");
            Enum::"Report Selection Usage Sales"::"Customer Statement":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"C.Statement");
            Enum::"Report Selection Usage Sales"::"Pro Forma Invoice":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Pro Forma S. Invoice");
            Enum::"Report Selection Usage Sales"::"Archived Blanket Order":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Arch.Blanket");
            Enum::"Report Selection Usage Sales"::"Sales Order Picking List":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"S.Sales Order Picking List");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2.AsInteger());
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        NewReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(NewReportUsage, Rec.GetFilter(Usage)) then
                case NewReportUsage of
                    Enum::"Report Selection Usage"::"S.Quote":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::Quote;
                    Enum::"Report Selection Usage"::"S.Blanket":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Blanket Order";
                    Enum::"Report Selection Usage"::"S.Order":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::Order;
                    Enum::"Report Selection Usage"::"S.Work Order":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Work Order";
                    Enum::"Report Selection Usage"::"S.Order Pick Instruction":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Pick Instruction";
                    Enum::"Report Selection Usage"::"S.Invoice":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::Invoice;
                    Enum::"Report Selection Usage"::"S.Invoice Draft":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Draft Invoice";
                    Enum::"Report Selection Usage"::"S.Return":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Return Order";
                    Enum::"Report Selection Usage"::"S.Cr.Memo":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Credit Memo";
                    Enum::"Report Selection Usage"::"S.Shipment":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::Shipment;
                    Enum::"Report Selection Usage"::"S.Ret.Rcpt.":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Return Receipt";
                    Enum::"Report Selection Usage"::"S.Test":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Sales Document - Test";
                    Enum::"Report Selection Usage"::"S.Test Prepmt.":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Prepayment Document - Test";
                    Enum::"Report Selection Usage"::"S.Arch.Quote":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Archived Quote";
                    Enum::"Report Selection Usage"::"S.Arch.Order":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Archived Order";
                    Enum::"Report Selection Usage"::"S.Arch.Return":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Archived Return Order";
                    Enum::"Report Selection Usage"::"C.Statement":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Customer Statement";
                    Enum::"Report Selection Usage"::"Pro Forma S. Invoice":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Pro Forma Invoice";
                    Enum::"Report Selection Usage"::"S.Arch.Blanket":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Archived Blanket Order";
                    Enum::"Report Selection Usage"::"S.Sales Order Picking List":
                        ReportUsage2 := Enum::"Report Selection Usage Sales"::"Sales Order Picking List";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Sales")
    begin
    end;
}

