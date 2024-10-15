page 18661 "Customer Allowed Sections"
{
    PageType = List;
    SourceTable = "Customer Allowed Sections";
    DelayedInsert = true;
    ShowFilter = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Customer No"; "Customer No")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Customer No. ';
                    Visible = false;
                }
                field("TDS Section"; "TDS Section")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the section codes as per the Income Tax Act 1961';
                }
                field("TDS Section Description"; "TDS Section Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the section description as per the Income Tax Act 1961';
                }
                field("Threshold Overlook"; "Threshold Overlook")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Select the check mark in this field to overlook the TDS Threshold amount.';
                }
                field("Surcharge Overlook"; "Surcharge Overlook")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Select the check mark in this field to overlook the TDS surcharge amount.';
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
                ToolTip = 'Send the data in the page to an Excel file for analysis or editing';

                trigger OnAction()
                var
                    ODataUtility: Codeunit ODataUtility;
                    TDSSectionCodeLbl: Label 'Code eq %1', Comment = '%1= TDS Section Code';
                begin
                    ODataUtility.EditWorksheetInExcel('Allowed Sections', CurrPage.ObjectId(false), TDSSectionCodeLbl);
                end;
            }
        }
    }
}