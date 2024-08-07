namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Calculation;

permissionset 9173 "Output Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in Output Jnl.';

    Permissions = tabledata Bin = R,
                  tabledata "Capacity Ledger Entry" = R,
                  tabledata "Capacity Unit of Measure" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = R,
                  tabledata "Item Journal Batch" = RI,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Machine Center" = R,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Prod. Order Line" = R,
                  tabledata "Prod. Order Routing Line" = R,
                  tabledata "Production Order" = R,
                  tabledata "Reason Code" = R,
                  tabledata Scrap = R,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata Stop = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Work Center" = R;
}
