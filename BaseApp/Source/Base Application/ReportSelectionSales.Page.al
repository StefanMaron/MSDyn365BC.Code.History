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
                OptionCaption = 'Quote,Blanket Order,Order,Invoice,Work Order,Return Order,Credit Memo,Shipment,Return Receipt,Sales Document - Test,Prepayment Document - Test,Archived Quote,Archived Order,Archived Return Order,Pick Instruction,Customer Statement,Draft Invoice,Pro Forma Invoice,Archived Blanket Order';
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
                field("Use for Email Body"; "Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';
                }
                field("Use for Email Attachment"; "Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related document will be attached to the email.';
                }
                field("Email Body Layout Code"; "Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; "Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body layout that is used.';

                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK("Report ID") then
                            Validate("Email Body Layout Code", CustomReportLayout.Code);
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
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option Quote,"Blanket Order","Order",Invoice,"Work Order","Return Order","Credit Memo",Shipment,"Return Receipt","Sales Document - Test","Prepayment Document - Test","Archived Quote","Archived Order","Archived Return Order","Pick Instruction","Customer Statement","Draft Invoice","Pro Forma Invoice","Archived Blanket Order";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                SetRange(Usage, Usage::"S.Quote");
            ReportUsage2::"Blanket Order":
                SetRange(Usage, Usage::"S.Blanket");
            ReportUsage2::Order:
                SetRange(Usage, Usage::"S.Order");
            ReportUsage2::"Work Order":
                SetRange(Usage, Usage::"S.Work Order");
            ReportUsage2::"Pick Instruction":
                SetRange(Usage, Usage::"S.Order Pick Instruction");
            ReportUsage2::Invoice:
                SetRange(Usage, Usage::"S.Invoice");
            ReportUsage2::"Draft Invoice":
                SetRange(Usage, Usage::"S.Invoice Draft");
            ReportUsage2::"Return Order":
                SetRange(Usage, Usage::"S.Return");
            ReportUsage2::"Credit Memo":
                SetRange(Usage, Usage::"S.Cr.Memo");
            ReportUsage2::Shipment:
                SetRange(Usage, Usage::"S.Shipment");
            ReportUsage2::"Return Receipt":
                SetRange(Usage, Usage::"S.Ret.Rcpt.");
            ReportUsage2::"Sales Document - Test":
                SetRange(Usage, Usage::"S.Test");
            ReportUsage2::"Prepayment Document - Test":
                SetRange(Usage, Usage::"S.Test Prepmt.");
            ReportUsage2::"Archived Quote":
                SetRange(Usage, Usage::"S.Arch.Quote");
            ReportUsage2::"Archived Order":
                SetRange(Usage, Usage::"S.Arch.Order");
            ReportUsage2::"Archived Return Order":
                SetRange(Usage, Usage::"S.Arch.Return");
            ReportUsage2::"Customer Statement":
                SetRange(Usage, Usage::"C.Statement");
            ReportUsage2::"Pro Forma Invoice":
                SetRange(Usage, Usage::"Pro Forma S. Invoice");
            ReportUsage2::"Archived Blanket Order":
                SetRange(Usage, Usage::"S.Arch.Blanket");
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
                    Usage::"S.Quote":
                        ReportUsage2 := ReportUsage2::Quote;
                    Usage::"S.Blanket":
                        ReportUsage2 := ReportUsage2::"Blanket Order";
                    Usage::"S.Order":
                        ReportUsage2 := ReportUsage2::Order;
                    Usage::"S.Work Order":
                        ReportUsage2 := ReportUsage2::"Work Order";
                    Usage::"S.Order Pick Instruction":
                        ReportUsage2 := ReportUsage2::"Pick Instruction";
                    Usage::"S.Invoice":
                        ReportUsage2 := ReportUsage2::Invoice;
                    Usage::"S.Invoice Draft":
                        ReportUsage2 := ReportUsage2::"Draft Invoice";
                    Usage::"S.Return":
                        ReportUsage2 := ReportUsage2::"Return Order";
                    Usage::"S.Cr.Memo":
                        ReportUsage2 := ReportUsage2::"Credit Memo";
                    Usage::"S.Shipment":
                        ReportUsage2 := ReportUsage2::Shipment;
                    Usage::"S.Ret.Rcpt.":
                        ReportUsage2 := ReportUsage2::"Return Receipt";
                    Usage::"S.Test":
                        ReportUsage2 := ReportUsage2::"Sales Document - Test";
                    Usage::"S.Test Prepmt.":
                        ReportUsage2 := ReportUsage2::"Prepayment Document - Test";
                    Usage::"S.Arch.Quote":
                        ReportUsage2 := ReportUsage2::"Archived Quote";
                    Usage::"S.Arch.Order":
                        ReportUsage2 := ReportUsage2::"Archived Order";
                    Usage::"S.Arch.Return":
                        ReportUsage2 := ReportUsage2::"Archived Return Order";
                    Usage::"C.Statement":
                        ReportUsage2 := ReportUsage2::"Customer Statement";
                    Usage::"Pro Forma S. Invoice":
                        ReportUsage2 := ReportUsage2::"Pro Forma Invoice";
                    Usage::"S.Arch.Blanket":
                        ReportUsage2 := ReportUsage2::"Archived Blanket Order";
                end;
            SetRange(Usage);
        end;
    end;
}

