permissionset 5540 "Service Documents - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read posted service documents';

    Permissions = tabledata "Job Ledger Entry" = R,
                  tabledata Loaner = Rm,
                  tabledata "Loaner Entry" = RM,
                  tabledata "Resource Location" = RIMD,
                  tabledata "Service Comment Line" = RIMD,
                  tabledata "Service Cr.Memo Header" = R,
                  tabledata "Service Cr.Memo Line" = R,
                  tabledata "Service Document Log" = R,
                  tabledata "Service Email Queue" = Rm,
                  tabledata "Service Invoice Header" = R,
                  tabledata "Service Invoice Line" = R,
                  tabledata "Service Item" = R,
                  tabledata "Service Item Log" = R,
                  tabledata "Service Ledger Entry" = R,
                  tabledata "Service Order Allocation" = r,
                  tabledata "Service Shipment Header" = R,
                  tabledata "Service Shipment Item Line" = R,
                  tabledata "Service Shipment Line" = R,
                  tabledata "Troubleshooting Header" = R,
                  tabledata "Troubleshooting Line" = R,
                  tabledata "Warranty Ledger Entry" = R;
}
