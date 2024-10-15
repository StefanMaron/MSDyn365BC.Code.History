permissionset 2345 "Intrastat - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Intrastat periodic activities';

    Permissions = tabledata Area = R,
                  tabledata "Country/Region" = R,
                  tabledata "Entry/Exit Point" = R,
                  tabledata "Intrastat Checklist Setup" = RIMD,
                  tabledata "Intrastat Currency Exch. Rate" = R,
                  tabledata "Intrastat Delivery Group" = R,
                  tabledata "Intrastat Jnl. Batch" = RIMD,
                  tabledata "Intrastat Jnl. Line" = RIMD,
                  tabledata "Intrastat Jnl. Template" = RIMD,
                  tabledata Item = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Specific Movement" = R,
                  tabledata "Stat. Reporting Setup" = R,
                  tabledata "Statistic Indication" = R,
                  tabledata "Tariff Number" = R,
                  tabledata "Transaction Specification" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Value Entry" = R;
}
