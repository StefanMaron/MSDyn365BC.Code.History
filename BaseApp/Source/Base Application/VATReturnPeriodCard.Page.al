page 738 "VAT Return Period Card"
{
    Caption = 'VAT Return Period';
    Editable = false;
    SourceTable = "VAT Return Period";

    layout
    {
        area(content)
        {
            group("Period Info")
            {
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
                    ToolTip = 'Specifies the due date for the VAT return period.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT return period.';
                }
                field("Received Date"; "Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT return period received date.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Receive Submitted VAT Returns")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receive Submitted VAT Returns';
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Receive the VAT returns that have been submitted.';
                Visible = IsReceiveSubmittedEnabled;
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
                ToolTip = 'Create a new VAT return from this VAT return period.';
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
                ToolTip = 'Open the VAT return card for this VAT return period.';
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

    trigger OnOpenPage()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get;
        IsReceiveSubmittedEnabled := VATReportSetup."Receive Submitted Return CU ID" <> 0;
    end;

    var
        CreateVATReturnEnabled: Boolean;
        OpenVATReturnEnabled: Boolean;
        IsReceiveSubmittedEnabled: Boolean;

    local procedure InitPageControllers()
    begin
        CreateVATReturnEnabled := Status = Status::Open;
        OpenVATReturnEnabled := true;
    end;
}

