page 2109 "O365 Customer Sales Documents"
{
    Caption = 'Invoices for Customer';
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
            repeater(Control15)
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
                    ToolTip = 'Specifies the total invoices amount, displayed in Brick view.';
                }
                field("Outstanding Status"; "Outstanding Status")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    StyleExpr = OutStandingStatusStyle;
                    ToolTip = 'Specifies the outstanding amount, meaning the amount not paid, displayed in Brick view.';
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
            action(View)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

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

                trigger OnAction()
                var
                    O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
                begin
                    O365SendResendInvoice.SendOrResendSalesDocument(Rec);
                end;
            }
            action(_NEW_TEMP_ESTIMATE)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = New;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "O365 Sales Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new estimate.';
                Visible = QuotesOnly AND NOT DisplayFailedMode;
            }
            action(_NEW_TEMP_DRAFT)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = New;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "O365 Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new Invoice';
                Visible = NOT DisplayFailedMode AND NOT QuotesOnly;
            }
            action(Clear)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Clear';
                Gesture = RightSwipe;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                Visible = DisplayFailedMode;

                trigger OnAction()
                var
                    O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
                begin
                    O365DocumentSendMgt.ClearNotificationsForDocument("No.", Posted, "Document Type");
                    CurrPage.Update(true);
                end;
            }
            action(ClearAll)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Clear all';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Page;
                Visible = DisplayFailedMode;

                trigger OnAction()
                var
                    O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
                begin
                    O365DocumentSendMgt.ClearNotificationsForAllDocuments;
                    CurrPage.Update(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        O365SalesManagement.GetO365DocumentBrickStyle(Rec, OutStandingStatusStyle);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(OnFind(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(OnNext(Steps));
    end;

    trigger OnOpenPage()
    begin
        // Check if document type is filtered to quotes - used for visibility of the New action
        QuotesOnly := StrPos(GetFilter("Document Type"), Format("Document Type"::Quote)) > 0;
    end;

    var
        OutStandingStatusStyle: Text[30];
        QuotesOnly: Boolean;
        DisplayFailedMode: Boolean;

    procedure SetDisplayFailedMode(NewDisplayFailedMode: Boolean)
    begin
        DisplayFailedMode := NewDisplayFailedMode;
    end;
}

