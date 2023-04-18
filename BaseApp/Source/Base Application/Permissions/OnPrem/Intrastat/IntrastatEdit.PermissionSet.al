permissionset 2345 "Intrastat - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Intrastat periodic activities';
    Permissions = tabledata Area = R,
                  tabledata "Country/Region" = R,
                  tabledata "Entry/Exit Point" = R,
#if not CLEAN22
                  tabledata "Advanced Intrastat Checklist" = RIMD,
                  tabledata "Intrastat Jnl. Batch" = RIMD,
                  tabledata "Intrastat Jnl. Line" = RIMD,
                  tabledata "Intrastat Jnl. Template" = RIMD,
#endif
                  tabledata Item = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Tariff Number" = R,
                  tabledata "Transaction Specification" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Value Entry" = R;
}
