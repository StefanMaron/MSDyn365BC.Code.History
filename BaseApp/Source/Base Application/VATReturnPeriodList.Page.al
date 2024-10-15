page 737 "VAT Return Period List"
{
    ApplicationArea = VAT;
    Caption = 'VAT Return Periods';
    CardPageID = "VAT Return Period Card";
    PageType = List;
    SourceTable = "VAT Return Period";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                Editable = IsEditable;
                ShowCaption = false;
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the VAT return period.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the VAT return period.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = WarningStyleExpr;
                    ToolTip = 'Specifies the due date for the VAT return period.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = WarningStyleExpr;
                    ToolTip = 'Specifies the status of the VAT return period.';
                }
                field("Received Date"; "Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT return period received date.';
                }
            }
        }
        area(factboxes)
        {
            part(Control9; "VAT Return Period FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get VAT Return Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get VAT Return Periods';
                Image = GetLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Load the VAT return periods that are set up in the system.';
                Visible = NOT IsEditable;
            }
            action("Create VAT Return")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create VAT Return';
                Enabled = CreateVATReturnEnabled;
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create a new VAT return from the selected VAT return period.';
            }
        }
        area(navigation)
        {
            action("Open VAT Return Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open VAT Return Card';
                Enabled = OpenVATReturnEnabled;
                Image = ShowList;
                ToolTip = 'Open the VAT return card for the selected VAT return period.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        InitPageControllers;
    end;

    trigger OnAfterGetRecord()
    begin
        InitPageControllers;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not IsEditable then
            Error('');
    end;

    trigger OnOpenPage()
    begin
        VATReportSetup.Get;
        IsEditable := VATReportSetup."Manual Receive Period CU ID" = 0;
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        WarningStyleExpr: Text;
        CreateVATReturnEnabled: Boolean;
        OpenVATReturnEnabled: Boolean;
        IsEditable: Boolean;

    local procedure InitPageControllers()
    begin
        CreateVATReturnEnabled := Status = Status::Open;
        OpenVATReturnEnabled := true;
        CheckOpenOrOverdue;
    end;

    local procedure CheckOpenOrOverdue()
    begin
        if (Status = Status::Open) and ("Due Date" <> 0D) and
           (("Due Date" < WorkDate) or
            VATReportSetup.IsPeriodReminderCalculation and
            ("Due Date" >= WorkDate) and ("Due Date" <= CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate)))
        then
            WarningStyleExpr := 'Unfavorable'
        else
            WarningStyleExpr := '';
    end;
}

