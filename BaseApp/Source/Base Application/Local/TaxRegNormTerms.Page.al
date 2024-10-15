page 17282 "Tax Reg. Norm Terms"
{
    Caption = 'Norm Term Names';
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Tax Reg. Norm Term";

    layout
    {
        area(content)
        {
            repeater(TermsList)
            {
                field("Term Code"; Rec."Term Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term code associated with the norm term name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term code description associated with the norm term name.';
                }
                field("Expression Type"; Rec."Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interval that you want to use as the rounding difference.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Check Term")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check Term';
                    Image = CheckList;
                    ToolTip = 'Verify the tax register term name.';

                    trigger OnAction()
                    begin
                        TaxRegTermMgt.CheckTaxRegTerm(
                          false, "Norm Jurisdiction Code",
                          DATABASE::"Tax Reg. Norm Term", DATABASE::"Tax Reg. Norm Term Formula");
                    end;
                }
            }
        }
    }

    var
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
}

