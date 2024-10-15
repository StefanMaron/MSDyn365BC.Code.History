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
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the VAT return period.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the VAT return period.';
                }
                field("Due Date"; Rec."Due Date")
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
                field("Received Date"; Rec."Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT return period received date.';
                }
                field("VAT Return No."; Rec."VAT Return No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the associated VAT return.';

                    trigger OnDrillDown()
                    begin
                        DrillDownVATReturn();
                    end;
                }
                field(VATReturnStatus; VATReturnStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Return Status';
                    Editable = false;
                    ToolTip = 'Specifies the status of the associated VAT return.';

                    trigger OnDrillDown()
                    begin
                        DrillDownVATReturn();
                    end;
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
                ToolTip = 'Load the VAT return periods that are set up in the system.';
                Visible = NOT IsEditable;

                trigger OnAction()
                var
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    VATReportMgt.GetVATReturnPeriods();
                end;
            }
            action("Create VAT Return")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create VAT Return';
                Enabled = CreateVATReturnEnabled;
                Image = RefreshLines;
                ToolTip = 'Create a new VAT return from the selected VAT return period.';

                trigger OnAction()
                var
                    VATReturnPeriod: Record "VAT Return Period";
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    CurrPage.SetSelectionFilter(VATReturnPeriod);
                    if VATReturnPeriod.Count = 1 then
                        VATReportMgt.CreateVATReturnFromVATPeriod(Rec);
                end;
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

                trigger OnAction()
                var
                    VATReturnPeriod: Record "VAT Return Period";
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    CurrPage.SetSelectionFilter(VATReturnPeriod);
                    if VATReturnPeriod.Count = 1 then
                        VATReportMgt.OpenVATReturnCardFromVATPeriod(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Get VAT Return Periods_Promoted"; "Get VAT Return Periods")
                {
                }
                actionref("Create VAT Return_Promoted"; "Create VAT Return")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        InitPageControllers();
    end;

    trigger OnAfterGetRecord()
    begin
        InitPageControllers();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not IsEditable then
            Error('');
    end;

    trigger OnOpenPage()
    begin
        VATReportSetup.Get();
        IsEditable := VATReportSetup."Manual Receive Period CU ID" = 0;
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        WarningStyleExpr: Text;
        CreateVATReturnEnabled: Boolean;
        OpenVATReturnEnabled: Boolean;
        IsEditable: Boolean;
        VATReturnStatus: Option " ",Open,Released,Submitted,Accepted,Closed,Rejected,Canceled;

    local procedure InitPageControllers()
    begin
        CreateVATReturnEnabled := (Status = Status::Open) and ("VAT Return No." = '');
        OpenVATReturnEnabled := (Status = Status::Open) or ("VAT Return No." <> '');
        CalcFields("VAT Return Status");
        if "VAT Return No." <> '' then
            VATReturnStatus := "VAT Return Status" + 1
        else
            VATReturnStatus := VATReturnStatus::" ";
        CheckOpenOrOverdue();
    end;
}

