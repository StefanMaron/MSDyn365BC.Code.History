#if not CLEAN20
permissionset 7227 "General Ledger XBRL - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read XBRL Taxonomies';

    Permissions = tabledata "XBRL Comment Line" = R,
                  tabledata "XBRL G/L Map Line" = R,
                  tabledata "XBRL Linkbase" = R,
                  tabledata "XBRL Rollup Line" = R,
                  tabledata "XBRL Schema" = R,
                  tabledata "XBRL Taxonomy" = R,
                  tabledata "XBRL Taxonomy Label" = R,
                  tabledata "XBRL Taxonomy Line" = R;

    ObsoleteTag = '20.0';
    ObsoleteState = Pending;
    ObsoleteReason = 'XBRL feature will be discontinued';
}
#endif