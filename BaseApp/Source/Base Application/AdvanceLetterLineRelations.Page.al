page 31018 "Advance Letter Line Relations"
{
    Caption = 'Advance Letter Line Relations';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Advance Letter Line Relation";

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                Caption = 'Lines';
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of posting desc. parameters';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document typ (order, invoice).';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document''s number of sales or purchase document (order, invoice).';
                }
                field("Document Line No."; "Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of line of sales or purchase document (order, invoice).';
                }
                field("Letter No."; "Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Letter Line No."; "Letter Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies letter line number.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount for the entry.';
                }
                field("Invoiced Amount"; "Invoiced Amount")
                {
                    ToolTip = 'Specifies the advance letter line invoiced amount.';
                    Visible = false;
                }
                field("Deducted Amount"; "Deducted Amount")
                {
                    ToolTip = 'Specifies the advance letter line deducted amount.';
                    Visible = false;
                }
                field("Amount To Deduct"; "Amount To Deduct")
                {
                    ToolTip = 'Specifies the maximum advance value for use in final sales invoice.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Cancel Advance Payment Relation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Cancel Advance Payment Relation';
                    Image = CancelLine;
                    ToolTip = 'This function cancels advance payment relation.';

                    trigger OnAction()
                    begin
                        CancelRelation(Rec, true, true, true);
                    end;
                }
            }
        }
    }
}

