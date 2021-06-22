page 2303 "BC O365 Invoice List"
{
    // NB! The name of the 'New' action has to be "_NEW_TEMP_" in order for the phone client to show the '+' sign in the list.

    Caption = 'Invoices';
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
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
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the number of the invoice, according to the specified number series.';
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
                    ToolTip = 'Specifies the total invoiced amount.';
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
                field("Outstanding Amount"; "Outstanding Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Outstanding Amount';
                    ToolTip = 'Specifies the total outstanding amount.';
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
                RunObject = Page "BC O365 Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new invoice.';
            }
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the selected invoice.';
                Visible = false;

                trigger OnAction()
                begin
                    OpenDocument;
                end;
            }
            action(ExportInvoices)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Export invoices';
                Image = Email;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Share an overview of sent invoices in an email.';

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"O365 Export Invoices");
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
        SetRange("Document Type", "Document Type"::Invoice);
    end;

    var
        OutStandingStatusStyle: Text[30];
}

