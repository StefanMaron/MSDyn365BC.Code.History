page 2103 "O365 Sales Document List"
{
    // NB! The name of the 'New' action has to be "_NEW_TEMP_" in order for the phone client to show the '+' sign in the list.

    Caption = 'Invoice List';
    DeleteAllowed = false;
    Editable = false;
    PageType = ListPart;
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
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the type of the document.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Sell-to Contact"; "Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the currency of amounts on the sales document.';
                }
                field("Currency Symbol"; "Currency Symbol")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the currency with its symbol, such as $ for Dollar. ';
                }
                field(Posted; Posted)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies if the document is posted.';
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the status of the document, such as Released or Open.';
                }
                field("Total Invoiced Amount"; "Total Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the total invoiced amount.';
                }
                field("Outstanding Status"; "Outstanding Status")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    StyleExpr = OutStandingStatusStyle;
                    ToolTip = 'Specifies the outstanding amount, meaning the amount not paid.';
                }
                field("Display No."; "Display No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowLatest)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Show all invoices';
                ToolTip = 'Show all invoices, sorted by their invoice date.';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted);
                    SetRange("Outstanding Amount");

                    SetSortByDocDate;
                end;
            }
            action(ShowUnpaid)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Show only unpaid invoices';
                Image = "Invoicing-Mail";
                ToolTip = 'Displays invoices that have not yet been paid in full, sorted by the due date.';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted, true);
                    SetFilter("Outstanding Amount", '>0');

                    SetSortByDueDate;

                    // go to "most late" document
                    FindPostedDocument('-');
                    CurrPage.Update;
                end;
            }
            action(ShowDraft)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Show only draft invoices';
                Image = "Invoicing-Document";
                ToolTip = 'Displays draft invoices and estimates';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted, false);
                    SetRange("Outstanding Amount");

                    SetSortByDocDate;
                end;
            }
            action(ShowSent)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Show only sent invoices';
                Image = "Invoicing-Send";
                ToolTip = 'Displays invoices that are sent, sorted by the invoice date.';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted, true);
                    SetRange("Outstanding Amount");

                    SetSortByDocDate;
                end;
            }
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
            action(Post)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Send';
                Gesture = LeftSwipe;
                Image = PostSendTo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';
                Visible = NOT HideActions;

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    O365SendResendInvoice.SendOrResendSalesDocument(Rec);
                end;
            }
            action(_NEW_TEMP_)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = New;
                RunObject = Page "BC O365 Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new Invoice.';
                Visible = NOT HideActions;
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

    var
        OutStandingStatusStyle: Text[30];
        HideActions: Boolean;

    procedure SetHideActions(NewHideActions: Boolean)
    begin
        HideActions := NewHideActions;
    end;
}

