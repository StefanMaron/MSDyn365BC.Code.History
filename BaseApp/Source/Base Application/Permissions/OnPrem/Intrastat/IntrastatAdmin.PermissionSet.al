permissionset 4384 "Intrastat - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Intrastat setup';

    Permissions = tabledata Area = RIMD,
                  tabledata "Entry/Exit Point" = RIMD,
                  tabledata "Intrastat Currency Exch. Rate" = RIMD,
                  tabledata "Intrastat Delivery Group" = RIMD,
                  tabledata "Intrastat Jnl. Template" = RIMD,
                  tabledata "Intrastat Setup" = RIM,
                  tabledata "Specific Movement" = RIMD,
                  tabledata "Stat. Reporting Setup" = RIMD,
                  tabledata "Statistic Indication" = RIMD,
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Transaction Specification" = RIMD,
                  tabledata "Transaction Type" = RIMD,
                  tabledata "Transport Method" = RIMD;
}
