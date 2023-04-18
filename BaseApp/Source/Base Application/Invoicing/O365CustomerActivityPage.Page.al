#if not CLEAN21
page 2101 "O365 Customer Activity Page"
{
    Caption = 'Customers';
    CardPageID = "O365 Sales Customer Card";
    DeleteAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    SourceTable = Customer;
    SourceTableView = SORTING(Name)
                      WHERE(Blocked = CONST(" "));
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
            action(DeleteLine)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Delete Customer';
                Gesture = RightSwipe;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
                ToolTip = 'Deletes the currently selected customer';

                trigger OnAction()
                begin
                    if not Confirm(DeleteQst) then
                        exit;

                    O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        "Balance Due (LCY)" := CalcOverdueBalance();
    end;

    trigger OnDeleteRecord(): Boolean
    var
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        O365SalesManagement.BlockOrDeleteCustomerAndDeleteContact(Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetRange("Date Filter", 0D, WorkDate());
        OverdueBalanceAutoFormatExpr := StrSubstNo(AutoFormatExprWithPrefixTxt, OverdueTxt);
    end;

    var
        DeleteQst: Label 'Are you sure?';
        AutoFormatExprWithPrefixTxt: Label '1,,%1', Locked = true;
        OverdueTxt: Label 'Overdue:';
        O365SalesManagement: Codeunit "O365 Sales Management";
        OverdueBalanceAutoFormatExpr: Text;
}
#endif
