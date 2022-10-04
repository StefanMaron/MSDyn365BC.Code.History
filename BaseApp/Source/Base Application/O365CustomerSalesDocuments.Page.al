#if not CLEAN21
page 2109 "O365 Customer Sales Documents"
{
    Caption = 'Invoices for Customer';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "O365 Sales Document";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Sell-to Customer Name");
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control15)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the type of the document.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the sales document.';
                }
                field("Currency Symbol"; Rec."Currency Symbol")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the currency with its symbol, such as $ for Dollar. ';
                }
                field(Posted; Posted)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies if the document is posted.';
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the status of the document, such as Released or Open.';
                }
                field("Total Invoiced Amount"; Rec."Total Invoiced Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the total invoices amount, displayed in Brick view.';
                }
                field("Outstanding Status"; Rec."Outstanding Status")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    StyleExpr = OutStandingStatusStyle;
                    ToolTip = 'Specifies the outstanding amount, meaning the amount not paid, displayed in Brick view.';
                }
                field("Display No."; Rec."Display No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'View';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    OpenDocument();
                end;
            }
            action(Post)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Send';
                Gesture = LeftSwipe;
                Image = PostSendTo;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = New;
                RunObject = Page "O365 Sales Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new estimate.';
                Visible = QuotesOnly AND NOT DisplayFailedMode;
            }
            action(_NEW_TEMP_DRAFT)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = New;
                RunObject = Page "O365 Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new Invoice';
                Visible = NOT DisplayFailedMode AND NOT QuotesOnly;
            }
            action(Clear)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Clear';
                Gesture = RightSwipe;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Clear all';
                Scope = Page;
                Visible = DisplayFailedMode;

                trigger OnAction()
                var
                    O365DocumentSendMgt: Codeunit "O365 Document Send Mgt";
                begin
                    O365DocumentSendMgt.ClearNotificationsForAllDocuments();
                    CurrPage.Update(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(_NEW_TEMP_ESTIMATE_Promoted; _NEW_TEMP_ESTIMATE)
                {
                }
                actionref(_NEW_TEMP_DRAFT_Promoted; _NEW_TEMP_DRAFT)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
                actionref(Clear_Promoted; Clear)
                {
                }
                actionref(ClearAll_Promoted; ClearAll)
                {
                }
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
#endif
