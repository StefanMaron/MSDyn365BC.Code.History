page 27006 "CFDI Relation Documents"
{
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "CFDI Relation Document";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Related Doc. Type"; "Related Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related document type.';
                }
                field("Related Doc. No."; "Related Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related document number.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Fiscal Invoice Number PAC"; "Fiscal Invoice Number PAC")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fiscal invoice number of the related document number.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(InsertRelatedCreditMemos)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Insert Related Credit Memos';
                Image = ReturnRelated;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Insert credit memo documents related to the current document line.';

                trigger OnAction()
                begin
                    InsertRelatedCreditMemos;
                end;
            }
        }
    }
}

