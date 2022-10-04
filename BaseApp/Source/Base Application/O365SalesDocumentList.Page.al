#if not CLEAN21
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
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
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
                    ToolTip = 'Specifies the total invoiced amount.';
                }
                field("Outstanding Status"; Rec."Outstanding Status")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    StyleExpr = OutStandingStatusStyle;
                    ToolTip = 'Specifies the outstanding amount, meaning the amount not paid.';
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
            action(ShowLatest)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show all invoices';
                ToolTip = 'Show all invoices, sorted by their invoice date.';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted);
                    SetRange("Outstanding Amount");

                    SetSortByDocDate();
                end;
            }
            action(ShowUnpaid)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show only unpaid invoices';
                Image = "Invoicing-Mail";
                ToolTip = 'Displays invoices that have not yet been paid in full, sorted by the due date.';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted, true);
                    SetFilter("Outstanding Amount", '>0');

                    SetSortByDueDate();

                    // go to "most late" document
                    FindPostedDocument('-');
                    CurrPage.Update();
                end;
            }
            action(ShowDraft)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show only draft invoices';
                Image = "Invoicing-Document";
                ToolTip = 'Displays draft invoices and estimates';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted, false);
                    SetRange("Outstanding Amount");

                    SetSortByDocDate();
                end;
            }
            action(ShowSent)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show only sent invoices';
                Image = "Invoicing-Send";
                ToolTip = 'Displays invoices that are sent, sorted by the invoice date.';
                Visible = NOT HideActions;

                trigger OnAction()
                begin
                    SetRange(Posted, true);
                    SetRange("Outstanding Amount");

                    SetSortByDocDate();
                end;
            }
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

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
                ApplicationArea = Invoicing, Basic, Suite;
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
        SetSortByDocDate();
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
#endif
