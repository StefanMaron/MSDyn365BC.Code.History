page 2302 "BC O365 Estimate List"
{
    // NB! The name of the 'New' action has to be "_NEW_TEMP_" in order for the phone client to show the '+' sign in the list.

    Caption = 'Estimates';
    Editable = false;
    PageType = List;
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
                    Caption = 'Estimate No.';
                    ToolTip = 'Specifies the number of the estimate, according to the specified number series.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Recipient';
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Total Invoiced Amount"; "Total Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the total estimated amount.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the due date of the document.';
                }
                field("Outstanding Status"; "Outstanding Status")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Status';
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
            action(_NEW_TEMP_)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = NewInvoice;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "BC O365 Sales Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new estimate.';
            }
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the selected estimate.';
                Visible = false;

                trigger OnAction()
                begin
                    OpenDocument;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        OutStandingStatusStyle := '';

        O365SalesManagement.GetO365DocumentBrickStyle(Rec, OutStandingStatusStyle);
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

    trigger OnOpenPage()
    begin
        SetRange("Document Type", "Document Type"::Quote);
        IgnoreInvoices;
    end;

    var
        OutStandingStatusStyle: Text[30];
}

