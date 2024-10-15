page 18005 "HSNSAC"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "HSN/SAC";
    Caption = 'HSNSAC';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("GST Group Code"; "GST Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies GST group code.';
                }
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies HSN/SAC codes for various groups.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies details of HSN/SAC code.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether GST group is for HSN/SAC.';
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
                    ODataUtility.EditWorksheetInExcel(
                        'HSNSAC',
                        CurrPage.ObjectId(false),
                        StrSubstNo(CodeValueLbl,
                        Rec."GST Group Code"));
                end;
            }
        }
    }
    var
        CodeValueLbl: Label 'Code %1', Comment = '%1 = GST Group Code';
}