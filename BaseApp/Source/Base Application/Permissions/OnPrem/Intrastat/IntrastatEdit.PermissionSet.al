permissionset 2345 "Intrastat - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Intrastat periodic activities';

    Permissions = tabledata Area = R,
                  tabledata "Country/Region" = R,
                  tabledata "Entry/Exit Point" = R,
#if not CLEAN19
                  tabledata "Intrastat Checklist Setup" = RIMD,
#endif
                  tabledata "Advanced Intrastat Checklist" = RIMD,
#if not CLEAN18
                  tabledata "Intrastat Currency Exch. Rate" = R,
                  tabledata "Intrastat Delivery Group" = R,
#endif
                  tabledata "Intrastat Jnl. Batch" = RIMD,
                  tabledata "Intrastat Jnl. Line" = RIMD,
                  tabledata "Intrastat Jnl. Template" = RIMD,
                  tabledata Item = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Variant" = R,
#if not CLEAN18
                  tabledata "Specific Movement" = R,
                  tabledata "Stat. Reporting Setup" = R,
#endif
                  tabledata "Tariff Number" = R,
                  tabledata "Transaction Specification" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Value Entry" = R;
}