permissionset 5585 "Dig. Voucher - Read"
{
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "Digital Voucher - Objects";

    Permissions = tabledata "Digital Voucher Entry Setup" = R,
                  tabledata "Digital Voucher Setup" = R,
                  tabledata "Voucher Entry Source Code" = R;
}
