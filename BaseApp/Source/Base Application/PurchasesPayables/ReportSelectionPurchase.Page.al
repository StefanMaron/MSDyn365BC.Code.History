page 347 "Report Selection - Purchase"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Purchase';
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
        ReportUsage2: Enum "Report Selection Usage Purchase";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Purchase"::Quote:
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Quote");
            "Report Selection Usage Purchase"::"Blanket Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Blanket");
            "Report Selection Usage Purchase"::Order:
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Order");
            "Report Selection Usage Purchase"::Invoice:
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Invoice");
            "Report Selection Usage Purchase"::"Return Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Return");
            "Report Selection Usage Purchase"::"Credit Memo":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Cr.Memo");
            "Report Selection Usage Purchase"::Receipt:
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Receipt");
            "Report Selection Usage Purchase"::"Return Shipment":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Ret.Shpt.");
            "Report Selection Usage Purchase"::"Purchase Document - Test":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Test");
            "Report Selection Usage Purchase"::"Prepayment Document - Test":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Test Prepmt.");
            "Report Selection Usage Purchase"::"Archived Quote":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Arch.Quote");
            "Report Selection Usage Purchase"::"Archived Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Arch.Order");
            "Report Selection Usage Purchase"::"Archived Return Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Arch.Return");
            "Report Selection Usage Purchase"::"Archived Blanket Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.Arch.Blanket");
            "Report Selection Usage Purchase"::"Vendor Remittance":
                Rec.SetRange(Usage, "Report Selection Usage"::"V.Remittance");
            "Report Selection Usage Purchase"::"Vendor Remittance - Posted Entries":
                Rec.SetRange(Usage, "Report Selection Usage"::"P.V.Remit.");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
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
                    "Report Selection Usage"::"P.Quote":
                        ReportUsage2 := "Report Selection Usage Purchase"::Quote;
                    "Report Selection Usage"::"P.Blanket":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Blanket Order";
                    "Report Selection Usage"::"P.Order":
                        ReportUsage2 := "Report Selection Usage Purchase"::Order;
                    "Report Selection Usage"::"P.Invoice":
                        ReportUsage2 := "Report Selection Usage Purchase"::Invoice;
                    "Report Selection Usage"::"P.Return":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Return Order";
                    "Report Selection Usage"::"P.Cr.Memo":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Credit Memo";
                    "Report Selection Usage"::"P.Receipt":
                        ReportUsage2 := "Report Selection Usage Purchase"::Receipt;
                    "Report Selection Usage"::"P.Ret.Shpt.":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Return Shipment";
                    "Report Selection Usage"::"P.Test":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Purchase Document - Test";
                    "Report Selection Usage"::"P.Test Prepmt.":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Prepayment Document - Test";
                    "Report Selection Usage"::"P.Arch.Quote":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Archived Quote";
                    "Report Selection Usage"::"P.Arch.Order":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Archived Order";
                    "Report Selection Usage"::"P.Arch.Return":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Archived Return Order";
                    "Report Selection Usage"::"P.Arch.Blanket",
                    "Report Selection Usage"::"S.Arch.Blanket": // Wrong enum case kept here to avoid semantically breaking change (BUG 448278)
                        ReportUsage2 := "Report Selection Usage Purchase"::"Archived Blanket Order";
                    "Report Selection Usage"::"V.Remittance":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Vendor Remittance";
                    "Report Selection Usage"::"P.V.Remit.":
                        ReportUsage2 := "Report Selection Usage Purchase"::"Vendor Remittance";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
    end;
}

