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
                OptionCaption = 'Quote,Blanket Order,Order,Invoice,Return Order,Credit Memo,Receipt,Return Shipment,Purchase Document - Test,Prepayment Document - Test,Archived Quote,Archived Order,Archived Return Order,Archived Blanket Order,Vendor Remittance,Vendor Remittance - Posted Entries';
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
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo",Receipt,"Return Shipment","Purchase Document - Test","Prepayment Document - Test","Archived Quote","Archived Order","Archived Return Order","Archived Blanket Order","Vendor Remittance","Vendor Remittance - Posted Entries";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                SetRange(Usage, Usage::"P.Quote");
            ReportUsage2::"Blanket Order":
                SetRange(Usage, Usage::"P.Blanket");
            ReportUsage2::Order:
                SetRange(Usage, Usage::"P.Order");
            ReportUsage2::Invoice:
                SetRange(Usage, Usage::"P.Invoice");
            ReportUsage2::"Return Order":
                SetRange(Usage, Usage::"P.Return");
            ReportUsage2::"Credit Memo":
                SetRange(Usage, Usage::"P.Cr.Memo");
            ReportUsage2::Receipt:
                SetRange(Usage, Usage::"P.Receipt");
            ReportUsage2::"Return Shipment":
                SetRange(Usage, Usage::"P.Ret.Shpt.");
            ReportUsage2::"Purchase Document - Test":
                SetRange(Usage, Usage::"P.Test");
            ReportUsage2::"Prepayment Document - Test":
                SetRange(Usage, Usage::"P.Test Prepmt.");
            ReportUsage2::"Archived Quote":
                SetRange(Usage, Usage::"P.Arch.Quote");
            ReportUsage2::"Archived Order":
                SetRange(Usage, Usage::"P.Arch.Order");
            ReportUsage2::"Archived Return Order":
                SetRange(Usage, Usage::"P.Arch.Return");
            ReportUsage2::"Archived Blanket Order":
                SetRange(Usage, Usage::"P.Arch.Blanket");
            ReportUsage2::"Vendor Remittance":
                SetRange(Usage, Usage::"V.Remittance");
            ReportUsage2::"Vendor Remittance - Posted Entries":
                SetRange(Usage, Usage::"P.V.Remit.");
        end;
        FilterGroup(0);
        CurrPage.Update;
    end;
}

