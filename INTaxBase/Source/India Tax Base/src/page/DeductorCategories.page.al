page 18545 "Deductor Categories"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Deductor Category";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of type of deductor /employer.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the type of deductor /employer.';
                }
                field("PAO Code Mandatory"; "PAO Code Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Pay and Accounts Office (PAO) is mandatory for deductor type Central Government.';
                }
                field("DDO Code Mandatory"; "DDO Code Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Drawing and Disbursing Officer (DDO) is mandatory for deductor type - Central Government.';
                }
                field("State Code Mandatory"; "State Code Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the state code is mandatory for deductor type -  State Government.';
                }
                field("Ministry Details Mandatory"; "Ministry Details Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the ministry details (ministry name and other) are mandatory for deductor type - Central Govt (A), Statutory body - Central Govt. (D) & Autonomous body - Central Govt. (G).';
                }
                field("Transfer Voucher No. Mandatory"; "Transfer Voucher No. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Transfer Voucher number is mandatory if the transaction is by book entry.';
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
                    DeductorCategoryCodeLbl: Label 'Code eq %1', Comment = '%1= Deductory Code';
                begin
                    ODataUtility.EditWorksheetInExcel(
                        'Deductor Categories',
                        CurrPage.ObjectId(false),
                        StrSubstNo(DeductorCategoryCodeLbl, Code));
                end;
            }
        }
    }
}