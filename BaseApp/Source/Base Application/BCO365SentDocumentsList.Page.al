page 2358 "BC O365 Sent Documents List"
{
    Caption = 'Documents not sent';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
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
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Recipient';
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the number of the invoice, according to the specified number series.';
                }
                field("Total Invoiced Amount"; "Total Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the total invoiced amount.';
                }
                field("Last Email Sent Time"; "Last Email Sent Time")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email failed time';
                }
                field("Outstanding Status"; "Outstanding Status")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Status';
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
            action(Clear)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Clear line';
                Image = CompleteLine;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Removes the notification. We will not notify you about this failure again.';

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
                Image = Completed;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Page;
                ToolTip = 'Empties the list of notifications. We will not notify you about these failures again.';

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
}

