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
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body layout that is used.';

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
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Sales";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Sales"::Quote:
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Quote");
            "Report Selection Usage Sales"::"Blanket Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Blanket");
            "Report Selection Usage Sales"::Order:
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Order");
            "Report Selection Usage Sales"::"Work Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Work Order");
            "Report Selection Usage Sales"::"Pick Instruction":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Order Pick Instruction");
            "Report Selection Usage Sales"::Invoice:
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Invoice");
            "Report Selection Usage Sales"::"Draft Invoice":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Invoice Draft");
            "Report Selection Usage Sales"::"Return Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Return");
            "Report Selection Usage Sales"::"Credit Memo":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Cr.Memo");
            "Report Selection Usage Sales"::Shipment:
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Shipment");
            "Report Selection Usage Sales"::"Return Receipt":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Ret.Rcpt.");
            "Report Selection Usage Sales"::"Sales Document - Test":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Test");
            "Report Selection Usage Sales"::"Prepayment Document - Test":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Test Prepmt.");
            "Report Selection Usage Sales"::"Archived Quote":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Arch.Quote");
            "Report Selection Usage Sales"::"Archived Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Arch.Order");
            "Report Selection Usage Sales"::"Archived Return Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Arch.Return");
            "Report Selection Usage Sales"::"Customer Statement":
                Rec.SetRange(Usage, "Report Selection Usage"::"C.Statement");
            "Report Selection Usage Sales"::"Pro Forma Invoice":
                Rec.SetRange(Usage, "Report Selection Usage"::"Pro Forma S. Invoice");
            "Report Selection Usage Sales"::"Archived Blanket Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"S.Arch.Blanket");
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
                    "Report Selection Usage"::"S.Quote":
                        ReportUsage2 := "Report Selection Usage Sales"::Quote;
                    "Report Selection Usage"::"S.Blanket":
                        ReportUsage2 := "Report Selection Usage Sales"::"Blanket Order";
                    "Report Selection Usage"::"S.Order":
                        ReportUsage2 := "Report Selection Usage Sales"::Order;
                    "Report Selection Usage"::"S.Work Order":
                        ReportUsage2 := "Report Selection Usage Sales"::"Work Order";
                    "Report Selection Usage"::"S.Order Pick Instruction":
                        ReportUsage2 := "Report Selection Usage Sales"::"Pick Instruction";
                    "Report Selection Usage"::"S.Invoice":
                        ReportUsage2 := "Report Selection Usage Sales"::Invoice;
                    "Report Selection Usage"::"S.Invoice Draft":
                        ReportUsage2 := "Report Selection Usage Sales"::"Draft Invoice";
                    "Report Selection Usage"::"S.Return":
                        ReportUsage2 := "Report Selection Usage Sales"::"Return Order";
                    "Report Selection Usage"::"S.Cr.Memo":
                        ReportUsage2 := "Report Selection Usage Sales"::"Credit Memo";
                    "Report Selection Usage"::"S.Shipment":
                        ReportUsage2 := "Report Selection Usage Sales"::Shipment;
                    "Report Selection Usage"::"S.Ret.Rcpt.":
                        ReportUsage2 := "Report Selection Usage Sales"::"Return Receipt";
                    "Report Selection Usage"::"S.Test":
                        ReportUsage2 := "Report Selection Usage Sales"::"Sales Document - Test";
                    "Report Selection Usage"::"S.Test Prepmt.":
                        ReportUsage2 := "Report Selection Usage Sales"::"Prepayment Document - Test";
                    "Report Selection Usage"::"S.Arch.Quote":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Quote";
                    "Report Selection Usage"::"S.Arch.Order":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Order";
                    "Report Selection Usage"::"S.Arch.Return":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Return Order";
                    "Report Selection Usage"::"C.Statement":
                        ReportUsage2 := "Report Selection Usage Sales"::"Customer Statement";
                    "Report Selection Usage"::"Pro Forma S. Invoice":
                        ReportUsage2 := "Report Selection Usage Sales"::"Pro Forma Invoice";
                    "Report Selection Usage"::"S.Arch.Blanket":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Blanket Order";
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

