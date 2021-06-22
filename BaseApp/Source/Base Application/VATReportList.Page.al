page 744 "VAT Report List"
{
    ApplicationArea = VAT;
    Caption = 'VAT Returns';
    CardPageID = "VAT Report";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    SourceTableView = WHERE("VAT Report Config. Code" = CONST("VAT Return"));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("VAT Report Config. Code"; "VAT Report Config. Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the appropriate configuration code.';
                    Visible = false;
                }
                field("VAT Report Type"; "VAT Report Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the start date of the report period for the VAT report.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the end date of the report period for the VAT report.';
                }
                field(Status; Status)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the status of the VAT report.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Create From VAT Return Period")
            {
                ApplicationArea = VAT;
                Caption = 'Create From VAT Return Period';
                Image = GetLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create a new VAT return from an existing VAT return period.';

                trigger OnAction()
                var
                    VATReturnPeriod: Record "VAT Return Period";
                    VATReportMgt: Codeunit "VAT Report Mgt.";
                begin
                    if PAGE.RunModal(0, VATReturnPeriod) = ACTION::LookupOK then
                        VATReportMgt.CreateVATReturnFromVATPeriod(VATReturnPeriod);
                end;
            }
        }
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = VAT;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"VAT Report", Rec);
                    end;
                }
                action("Open VAT Return Period Card")
                {
                    ApplicationArea = VAT;
                    Caption = 'Open VAT Return Period Card';
                    Image = ShowList;
                    ToolTip = 'Open the VAT return period card for the selected VAT return.';
                    Visible = ReturnPeriodEnabled;

                    trigger OnAction()
                    var
                        VATReportMgt: Codeunit "VAT Report Mgt.";
                    begin
                        VATReportMgt.OpenVATPeriodCardFromVATReturn(Rec);
                    end;
                }
            }
            action("Report Setup")
            {
                ApplicationArea = VAT;
                Caption = 'Report Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
                Visible = false;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ReturnPeriodEnabled := "Return Period No." <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        ReturnPeriodEnabled := "Return Period No." <> '';
    end;

    var
        ReturnPeriodEnabled: Boolean;
}

