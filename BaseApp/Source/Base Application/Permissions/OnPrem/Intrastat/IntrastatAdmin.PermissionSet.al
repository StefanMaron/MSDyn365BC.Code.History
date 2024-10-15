permissionset 4384 "Intrastat - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Intrastat setup';

    Permissions = tabledata Area = RIMD,
                  tabledata "Entry/Exit Point" = RIMD,
#if not CLEAN18
                  tabledata "Intrastat Currency Exch. Rate" = RIMD,
                  tabledata "Intrastat Delivery Group" = RIMD,
#endif
                  tabledata "Intrastat Jnl. Template" = RIMD,
                  tabledata "Intrastat Setup" = RIM,
#if not CLEAN18
                  tabledata "Specific Movement" = RIMD,
                  tabledata "Stat. Reporting Setup" = RIMD,
#endif
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Transaction Specification" = RIMD,
                  tabledata "Transaction Type" = RIMD,
                  tabledata "Transport Method" = RIMD;
}