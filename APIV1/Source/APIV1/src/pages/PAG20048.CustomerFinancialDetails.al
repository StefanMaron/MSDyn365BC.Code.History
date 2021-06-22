page 20048 "Customer Financial Details"
{
    PageType = API;
    EntityName = 'customerFinancialDetail';
    EntitySetName = 'customerFinancialDetails';
    SourceTable = 18;
    Editable = false;
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;
    Extensible = false;


    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                    Editable = false;
                }
                field(balance; "Balance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'balance', Locked = true;
                    Editable = false;
                }
                field(totalSalesExcludingTax; "Sales (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'totalSalesExcludingTax', Locked = true;
                    Editable = false;
                }
                field(overdueAmount; "Balance Due (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'overdueAmount', Locked = true;
                    Editable = false;
                }
            }
        }

    }

    actions
    {
    }
    trigger OnAfterGetRecord()
    begin
        SETRANGE("Date Filter", 0D, WorkDate() - 1);
        CALCFIELDS("Balance Due (LCY)", "Sales (LCY)", "Balance (LCY)");
    end;

}