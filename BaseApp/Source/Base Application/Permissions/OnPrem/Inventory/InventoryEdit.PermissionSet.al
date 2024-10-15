namespace System.Security.AccessControl;

using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Intrastat;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Location;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.BOM;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Service.Contract;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Analysis;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.ADCS;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Tracking;
using Microsoft.Service.Loaner;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Planning;
using Microsoft.Warehouse.History;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Resources;
using Microsoft.Sales.History;
using Microsoft.Manufacturing.Routing;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Pricing;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Document;
using Microsoft.Service.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Service.Maintenance;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.MarketingText;

permissionset 8562 "Inventory - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit items/BOMs/SKUs';

    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = r,
                  tabledata "Bin Content" = Rd,
                  tabledata "BOM Component" = RIMD,
                  tabledata "Capacity Ledger Entry" = rm,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "Filed Contract Line" = r,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = RIMD,
                  tabledata "Item Analysis View Budg. Entry" = Rd,
                  tabledata "Item Analysis View Entry" = Rid,
                  tabledata "Item Budget Entry" = R,
                  tabledata "Item Category" = R,
                  tabledata "Item Charge Assignment (Purch)" = r,
                  tabledata "Item Charge Assignment (Sales)" = r,
                  tabledata "Item Discount Group" = RIMD,
                  tabledata "Item Identifier" = RD,
                  tabledata "Item Journal Line" = Rm,
                  tabledata "Item Journal Template" = R,
                  tabledata "Item Ledger Entry" = Rm,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Substitution" = RIMD,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Translation" = RIMD,
                  tabledata "Item Unit of Measure" = RIMD,
                  tabledata "Item Variant" = RIMD,
                  tabledata "Item Vendor" = RIMD,
                  tabledata "Job Journal Line" = r,
                  tabledata "Job Ledger Entry" = r,
                  tabledata "Job Planning Line - Calendar" = r,
                  tabledata "Job Planning Line" = r,
                  tabledata Loaner = r,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Marketing Text Attributes" = RIMD,
                  tabledata "Nonstock Item" = RIMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Phys. Inventory Ledger Entry" = Rm,
                  tabledata "Phys. Invt. Counting Period" = R,
                  tabledata "Planning Component" = Rm,
                  tabledata "Posted Whse. Receipt Line" = R,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm,
                  tabledata "Production BOM Header" = R,
                  tabledata "Production BOM Line" = R,
                  tabledata "Production Forecast Entry" = rm,
                  tabledata "Production Order" = rm,
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Line" = r,
                  tabledata "Purch. Rcpt. Line" = r,
                  tabledata "Purchase Discount Access" = RIMD,
                  tabledata "Purchase Line" = Rm,
#if not CLEAN23
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
#endif
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata "Put-away Template Header" = R,
                  tabledata "Registered Whse. Activity Line" = r,
                  tabledata "Requisition Line" = Rm,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata Resource = R,
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Routing Header" = R,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Discount Access" = RimD,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Line" = Rm,
#if not CLEAN23
                  tabledata "Sales Line Discount" = RimD,
                  tabledata "Sales Price" = RIMD,
#endif
                  tabledata "Sales Price Access" = RIMD,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Serv. Price Adjustment Detail" = r,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Invoice Line" = R,
                  tabledata "Service Item" = R,
                  tabledata "Service Item Component" = R,
                  tabledata "Service Item Group" = R,
                  tabledata "Service Item Line" = r,
                  tabledata "Service Ledger Entry" = r,
                  tabledata "Special Equipment" = R,
                  tabledata "Standard Item Journal Line" = RM,
                  tabledata "Standard Purchase Line" = rm,
                  tabledata "Standard Sales Line" = r,
                  tabledata "Stockkeeping Unit" = RIMD,
                  tabledata "Stockkeeping Unit Comment Line" = RIMD,
                  tabledata "Substitution Condition" = RIMD,
                  tabledata "Tariff Number" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transfer Line" = R,
                  tabledata "Transfer Receipt Line" = r,
                  tabledata "Transfer Shipment Line" = r,
                  tabledata "Troubleshooting Setup" = Rd,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = RIMD,
                  tabledata "Value Entry" = Rm,
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
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Warehouse Activity Header" = r,
                  tabledata "Warehouse Activity Line" = r,
                  tabledata "Warehouse Class" = R,
                  tabledata "Warehouse Entry" = r,
                  tabledata "Warehouse Journal Line" = r,
                  tabledata "Warehouse Receipt Line" = r,
                  tabledata "Warehouse Reason Code" = r,
                  tabledata "Warehouse Request" = r,
                  tabledata "Warehouse Shipment Line" = r,
                  tabledata "Warranty Ledger Entry" = r,
                  tabledata "Whse. Cross-Dock Opportunity" = r,
                  tabledata "Whse. Worksheet Line" = r;
}
