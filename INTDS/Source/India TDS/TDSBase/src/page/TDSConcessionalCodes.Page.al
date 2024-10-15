page 18690 "TDS Concessional Codes"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    DelayedInsert = true;
    SourceTable = "TDS Concessional Code";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the vendor code';
                }
                field(Section; Section)
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
                    VendorNoLbl: Label 'Code eq %1', Comment = '%1 = Vendor No.';
                begin
                    ODataUtility.EditWorksheetInExcel('Vendor Concessional Codes', CurrPage.ObjectId(false), StrSubstNo(VendorNoLbl, Rec."Vendor No."));
                end;
            }
        }
    }
}