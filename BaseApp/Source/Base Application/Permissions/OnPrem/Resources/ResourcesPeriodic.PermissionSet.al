permissionset 9338 "Resources - Periodic"
{
    Access = Public;
    Assignable = false;
    Caption = 'Resource periodic activities';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Date Compr. Register" = R,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Res. Ledger Entry" = Rid,
                  tabledata Resource = RM,
                  tabledata "Resource Group" = R,
#if not CLEAN21
                  tabledata "Resource Price" = RIMD,
                  tabledata "Resource Price Change" = RIMD,
#endif
                  tabledata "Resource Register" = Rd,
                  tabledata "Rounding Method" = R,
                  tabledata "Source Code Setup" = R;
}
