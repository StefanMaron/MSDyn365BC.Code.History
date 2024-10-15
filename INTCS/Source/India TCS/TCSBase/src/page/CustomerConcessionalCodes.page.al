page 18808 "Customer Concessional Codes"
{
    PageType = List;
    UsageCategory = Lists;
    DelayedInsert = true;
    SourceTable = "Customer Concessional Code";
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("TCS Nature of Collection"; "TCS Nature of Collection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the TCS Nature of collection under which tax has been collected.';
                }
                field("Description"; "Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the TCS Nature of Collection.';
                }
                field("Concessional Code"; "Concessional Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Concessional Code if concessional rate is applicable.';
                }
                field("Reference No."; "Concessional Form No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the concessional form/certificate number.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the particular Concessional Code.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the particular Concessional Code.';
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
                    CodeLbl: Label 'Code eq ''%1''', Comment = '%1=Customer No.';
                begin
                    ODataUtility.EditWorksheetInExcel('Customer Concessional Codes', CurrPage.ObjectId(false), StrSubstNo(CodeLbl, Rec."customer No."));
                end;
            }
        }
    }
}