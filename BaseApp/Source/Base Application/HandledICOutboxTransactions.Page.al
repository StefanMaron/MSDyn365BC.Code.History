page 613 "Handled IC Outbox Transactions"
{
    ApplicationArea = Intercompany;
    Caption = 'Handled Intercompany Outbox Transactions';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Functions,Outbox Transaction';
    SourceTable = "Handled IC Outbox Trans.";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction No."; "Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the transaction''s entry number.';
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies what action has been taken on the transaction.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document, or a purchase document.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Transaction Source"; "Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Outbox Transaction")
            {
                Caption = '&Outbox Transaction';
                Image = Export;
                action(Details)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Details';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'View transaction details.';

                    trigger OnAction()
                    begin
                        ShowDetails;
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    RunObject = Page "IC Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Handled IC Outbox Transaction"),
                                  "Transaction No." = FIELD("Transaction No."),
                                  "IC Partner Code" = FIELD("IC Partner Code"),
                                  "Transaction Source" = FIELD("Transaction Source");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re-create Outbox Transaction")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Re-create Outbox Transaction';
                    Image = NewStatusChange;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Re-creates a transaction in the outbox. For example, if you accepted a transaction in your outbox but then deleted the document or journal instead of posting it, you can re-create the outbox entry and accept it again.';

                    trigger OnAction()
                    var
                        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
                    begin
                        ICInboxOutboxMgt.RecreateOutboxTransaction(Rec);
                    end;
                }
            }
        }
    }
}

