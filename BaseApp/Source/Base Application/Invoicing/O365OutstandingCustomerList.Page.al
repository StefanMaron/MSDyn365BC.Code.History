#if not CLEAN21
page 2108 "O365 Outstanding Customer List"
{
    Caption = 'Customers';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = Customer;
    SourceTableView = SORTING(Name);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Caption = '';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the customer''s name. This name will appear on all sales documents for the customer.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the customer''s telephone number.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this customer.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                    trigger OnDrillDown()
                    begin
                        OpenCustomerLedgerEntries(false);
                    end;
                }
                field("Balance Due (LCY)"; Rec."Balance Due (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = OverdueBalanceAutoFormatExpr;
                    AutoFormatType = 10;
                    BlankZero = true;
                    Style = Attention;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';

                    trigger OnDrillDown()
                    begin
                        OpenCustomerLedgerEntries(true);
                    end;
                }
                field("Sales (LCY)"; Rec."Sales (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    ToolTip = 'Specifies the total net amount of sales to the customer in LCY.';
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
                Gesture = None;
                Image = ViewDetails;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                var
                    O365SalesDocument: Record "O365 Sales Document";
                begin
                    O365SalesDocument.SetRange(Posted, true);
                    O365SalesDocument.SetFilter("Outstanding Amount", '>0');
                    O365SalesDocument.SetFilter("Sell-to Customer No.", "No.");
                    O365SalesDocument.SetSortByDocDate();

                    PAGE.Run(PAGE::"O365 Customer Sales Documents", O365SalesDocument);
                end;
            }
            action(NewSalesInvoice)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New Invoice';
                Gesture = LeftSwipe;
                Image = NewSalesInvoice;
                Scope = Repeater;
                ToolTip = 'Create a new invoice for the customer.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    SalesHeader.Init();
                    SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
                    SalesHeader.Validate("Sell-to Customer No.", "No.");
                    SalesHeader.Insert(true);
                    Commit();

                    PAGE.Run(PAGE::"O365 Sales Invoice", SalesHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(NewSalesInvoice_Promoted; NewSalesInvoice)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetRange("Date Filter", 0D, WorkDate() - 1);
        CalcFields("Balance Due (LCY)");
        SetRange("Date Filter", 0D, WorkDate());
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        BlockCustomerAndDeleteContact();
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetRange("Date Filter", 0D, WorkDate());
        OverdueBalanceAutoFormatExpr := StrSubstNo(AutoFormatExprWithPrefixTxt, OverdueTxt);
    end;

    var
        AutoFormatExprWithPrefixTxt: Label '1,,%1', Locked = true;
        OverdueTxt: Label 'Overdue:';
        OverdueBalanceAutoFormatExpr: Text;

    local procedure BlockCustomerAndDeleteContact()
    var
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        Blocked := Blocked::All;
        Modify(true);
        CustContUpdate.DeleteCustomerContacts(Rec);
        CurrPage.Update();
    end;
}
#endif
