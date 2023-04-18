#if not CLEAN21
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
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Estimate No.';
                    ToolTip = 'Specifies the number of the estimate, according to the specified number series.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Recipient';
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Total Invoiced Amount"; Rec."Total Invoiced Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the total estimated amount.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the due date of the document.';
                }
                field("Outstanding Status"; Rec."Outstanding Status")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = NewInvoice;
                RunObject = Page "BC O365 Sales Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new estimate.';
            }
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the selected estimate.';
                Visible = false;

                trigger OnAction()
                begin
                    OpenDocument();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(_NEW_TEMP__Promoted; _NEW_TEMP_)
                {
                }
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

    trigger OnOpenPage()
    begin
        SetRange("Document Type", "Document Type"::Quote);
        IgnoreInvoices();
    end;

    var
        OutStandingStatusStyle: Text[30];
}
#endif
