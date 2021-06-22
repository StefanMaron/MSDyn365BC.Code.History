permissionset 9412 "Prepayment - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Prepayment Setup';

    Permissions = tabledata "Purchase Prepayment %" = RIMD,
                  tabledata "Sales Prepayment %" = RIMD;
}
