page 18001 "GST Group"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "GST Group";
    Caption = 'GST Group';
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code which needs to be assigned to identify a GST group, should be one unique code, both number and letters are allowed.';

                }
                field("GST Group Type"; "GST Group Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the GST group is assigned for goods or service.';


                }
                field("GST Place Of Supply"; "GST Place Of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location state code which system should consider for GST calculation.';


                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the GST group.';


                }
                field("Reverse Charge"; "Reverse Charge")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the reverse charge is applicable for this GST group or not.';
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
                begin
                    ODataUtility.EditWorksheetInExcel('GST Group',
                    CurrPage.ObjectId(false),
                    StrSubstNo(CodeValueLbl, Rec.Code));
                end;


            }

        }
    }
    Var
        CodeValueLbl: Label 'Code %1', Comment = '%1 = GST Group Code';
}