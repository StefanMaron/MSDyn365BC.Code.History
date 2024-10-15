page 18687 "Allowed Sections"
{
    PageType = List;
    SourceTable = "Allowed Sections";
    DelayedInsert = true;
    ShowFilter = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Vendor No"; "Vendor No")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Vendor No. ';
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

                field("Default Section"; "Default Section")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Select the check mark if the section has to be auto updated in the transaction.';
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
                field("Non Resident Payments"; "Non Resident Payments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the section belongs to Non Resident payments.';
                }
                field("Nature of Remittance"; "Nature of Remittance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the type of remittance deductee deals with.';
                }
                field("Act Applicable"; "Act Applicable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the tax rates prescribed under the IT Act or DTAA.';
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
                    SectionCodeLbl: Label 'Code eq %1', Comment = '%1 = TDS Section Code';
                begin
                    ODataUtility.EditWorksheetInExcel('Allowed Sections', CurrPage.ObjectId(false), StrSubstNo(SectionCodeLbl, Rec."TDS Section"));
                end;
            }
        }
    }
}