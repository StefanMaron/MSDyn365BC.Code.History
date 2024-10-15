page 18662 "TDS Cust Concessional Codes"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    DelayedInsert = true;
    SourceTable = "TDS Customer Concessional Code";
    Caption = 'TDS Customer Concessional Codes';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the Customer code';
                }
                field("TDS Section Code"; "TDS Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the Section codes under which tax has been deducted.';
                }

                field("Concessional Code"; "Concessional Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the concessional code if concessional rate is applicable.';
                }
                field("Certificate No."; "Certificate No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the concessional form/certificate number of the deductee.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the starting date of concessional certificate issued.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the ending date of concessional certificate issued.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditInExcel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in Excel';
                Image = Excel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Send the data in the  page to an Excel file for analysis or editing';

                trigger OnAction()
                var
                    ODataUtility: Codeunit ODataUtility;
                begin
                    ODataUtility.EditWorksheetInExcel('Customer Concessional Codes', CurrPage.ObjectId(false), StrSubstNo('Code eq ''%1''', Rec."Customer No."));
                end;
            }
        }
    }
}