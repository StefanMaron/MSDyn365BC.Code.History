#if not CLEAN20
permissionset 2252 "General Ledger XBRL - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create, edit XBRL Taxonomies';

    Permissions = tabledata "XBRL Comment Line" = RIMD,
                  tabledata "XBRL G/L Map Line" = RIMD,
                  tabledata "XBRL Linkbase" = RIMD,
                  tabledata "XBRL Rollup Line" = RIMD,
                  tabledata "XBRL Schema" = RIMD,
                  tabledata "XBRL Taxonomy" = RIMD,
                  tabledata "XBRL Taxonomy Label" = RIMD,
                  tabledata "XBRL Taxonomy Line" = RIMD;

    ObsoleteTag = '20.0';
    ObsoleteState = Pending;
    ObsoleteReason = 'XBRL feature will be discontinued';
}
#endif