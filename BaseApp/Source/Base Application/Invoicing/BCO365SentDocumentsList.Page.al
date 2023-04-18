#if not CLEAN21
page 2358 "BC O365 Sent Documents List"
{
    Caption = 'Documents not sent';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
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
            repeater(Control2)
            {
                ShowCaption = false;
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Recipient';
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the number of the invoice, according to the specified number series.';
                }
                field("Total Invoiced Amount"; Rec."Total Invoiced Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the total invoiced amount.';
                }
                field("Last Email Sent Time"; Rec."Last Email Sent Time")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Email failed time';
                }
                field("Outstanding Status"; Rec."Outstanding Status")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                    OpenDocument();
                end;
            }
            action(Clear)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Clear line';
                Image = CompleteLine;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Clear all';
                Image = Completed;
                Scope = Page;
                ToolTip = 'Empties the list of notifications. We will not notify you about these failures again.';

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
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Clear_Promoted; Clear)
                {
                }
                actionref(ClearAll_Promoted; ClearAll)
                {
                }
            }
        }
    }

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
}
#endif
