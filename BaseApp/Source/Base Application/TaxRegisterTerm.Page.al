page 17207 "Tax Register Term"
{
    Caption = 'Tax Register Term';
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Tax Register Term";

    layout
    {
        area(content)
        {
            repeater(TermsList)
            {
                field("Term Code"; "Term Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term code associated with the tax register term name.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register term name.';
                }
                field("Expression Type"; "Expression Type")
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
                field("Rounding Precision"; "Rounding Precision")
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Verify the tax register term name.';

                    trigger OnAction()
                    begin
                        TaxRegTermMgt.CheckTaxRegTerm(
                          false, "Section Code",
                          DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula");
                    end;
                }
            }
        }
    }

    var
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
}

