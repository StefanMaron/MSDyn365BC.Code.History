page 986 "Document Search Result"
{
    Caption = 'Document Search Result';
    Editable = false;
    PageType = List;
    SourceTable = "Document Search Result";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Doc. No.")
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Doc. No."; "Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about a non-posted document that is found using the Document Search window during manual payment processing.';

                    trigger OnDrillDown()
                    begin
                        PaymentRegistrationMgt.ShowRecords(Rec);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about a non-posted document that is found using the Document Search window during manual payment processing.';

                    trigger OnDrillDown()
                    begin
                        PaymentRegistrationMgt.ShowRecords(Rec);
                    end;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about a non-posted document that is found using the Document Search window during manual payment processing.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show';
                Image = ShowSelected;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Open the document on the selected line.';

                trigger OnAction()
                begin
                    PaymentRegistrationMgt.ShowRecords(Rec);
                end;
            }
        }
    }

    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
}

