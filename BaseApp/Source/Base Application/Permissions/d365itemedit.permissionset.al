namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.Warehouse.Structure;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.ADCS;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Planning;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Period;
using Microsoft.Sales.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.RateChange;

using Microsoft.Service.Resources;
using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;

permissionset 5947 "D365 ITEM, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create items';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Avg. Cost Adjmt. Entry Point" = rimd,
                  tabledata "Assembly Header" = R,
                  tabledata "Assembly Line" = R,
                  tabledata "Bin Content" = Rd,
                  tabledata Currency = RM,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata Item = RIMD,
                  tabledata "Item Analysis View" = RIMD,
                  tabledata "Item Analysis View Budg. Entry" = RIMD,
                  tabledata "Item Analysis View Entry" = RIMD,
                  tabledata "Item Analysis View Filter" = RIMD,
                  tabledata "Item Attribute Value Mapping" = RIMD,
                  tabledata "Item Budget Entry" = RIMD,
                  tabledata "Item Budget Name" = RIMD,
                  tabledata "Item Category" = R,
                  tabledata "Item Charge Assignment (Purch)" = r,
                  tabledata "Item Charge Assignment (Sales)" = r,
                  tabledata "Item Discount Group" = RIMD,
                  tabledata "Item Identifier" = RIMD,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Translation" = RIMD,
                  tabledata "Item Vendor" = RIMD,
                  tabledata "Inventory Adjmt. Entry (Order)" = Rimd,
                  tabledata "Job Planning Line" = R,
                  tabledata "My Item" = RIMD,
                  tabledata "Nonstock Item" = RIMD,
                  tabledata "Planning Assignment" = Rd,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Production BOM Line" = R,
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Line" = r,
                  tabledata "Purch. Rcpt. Line" = r,
                  tabledata "Purchase Discount Access" = RIMD,
#if not CLEAN25
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
#endif
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Discount Access" = RimD,
                  tabledata "Sales Invoice Line" = r,
#if not CLEAN25
                  tabledata "Sales Line Discount" = RimD,
                  tabledata "Sales Price" = RIMD,
#endif
                  tabledata "Sales Price Access" = RIMD,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Special Equipment" = R,
                  tabledata "Standard Item Journal" = RIMD,
                  tabledata "Standard Item Journal Line" = RIMD,
                  tabledata "Standard Purchase Line" = rm,
                  tabledata "Stockkeeping Unit" = RIMD,
                  tabledata "Stockkeeping Unit Comment Line" = RIMD,
                  tabledata "Substitution Condition" = RIMD,
                  tabledata "Tariff Number" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transfer Line" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "Vendor Bank Account" = R,

                  // Service
                  tabledata "Resource Skill" = RIMD,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Item" = RM,
                  tabledata "Service Item Component" = RM,
                  tabledata "Service Ledger Entry" = Rm,
                  tabledata "Troubleshooting Setup" = RIMD,
                  tabledata "Warranty Ledger Entry" = RM;
}
