page 2190 "O365 Invoicing Sales Doc. List"
{
    Caption = 'Invoices';
    DeleteAllowed = false;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Invoice';
    RefreshOnActivate = true;
    SourceTable = "O365 Sales Document";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Sell-to Customer Name");

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Total Invoiced Amount"; "Total Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Style = Ambiguous;
                    StyleExpr = NOT Posted;
                    ToolTip = 'Specifies the total invoiced amount.';
                }
                field("Outstanding Status"; "Outstanding Status")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    StyleExpr = OutStandingStatusStyle;
                    ToolTip = 'Specifies the outstanding amount, meaning the amount not paid.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                begin
                    OpenDocument;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OutStandingStatusStyle := '';
        if IsOverduePostedInvoice then
            OutStandingStatusStyle := 'Unfavorable'
        else
            if Posted and not Canceled and ("Outstanding Amount" <= 0) then
                OutStandingStatusStyle := 'Favorable';
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(OnFind(Which));
    end;

    trigger OnInit()
    begin
        SetSortByDocDate;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(OnNext(Steps));
    end;

    var
        OutStandingStatusStyle: Text[30];
}

