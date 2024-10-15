permissionset 8651 "Recievables Documents - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create sales orders etc.';

    IncludedPermissionSets = "Language - Read";

    Permissions = tabledata "Bank Account" = R,
                  tabledata Bin = R,
                  tabledata "BOM Component" = R,
                  tabledata "Close Opportunity Code" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Invoice Disc." = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "Entry Summary" = RIMD,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = R,
                  tabledata "Inventory Posting Group" = R,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = Ri,
                  tabledata "Item Charge" = R,
                  tabledata "Item Charge Assignment (Purch)" = Rm,
                  tabledata "Item Charge Assignment (Sales)" = RIMD,
#if not CLEAN19
                  tabledata "Item Cross Reference" = R,
#endif
                  tabledata "Item Journal Line" = Rm,
                  tabledata "Item Ledger Entry" = Rm,
                  tabledata "Item Reference" = R,
                  tabledata "Item Substitution" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Translation" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Job = R,
                  tabledata "Job Ledger Entry" = Rm,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Posting Buffer" = RIMD,
                  tabledata "Job Task" = R,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "My Customer" = Rimd,
                  tabledata "My Item" = Rimd,
                  tabledata Opportunity = R,
                  tabledata "Opportunity Entry" = RIM,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Planning Assignment" = Ri,
                  tabledata "Planning Component" = Rm,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm,
                  tabledata "Purchase Header" = R,
                  tabledata "Purchase Line" = Rm,
                  tabledata "Reason Code" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Requisition Line" = Rim,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata Resource = R,
#if not CLEAN21
                  tabledata "Resource Cost" = R,
                  tabledata "Resource Price" = R,
#endif
                  tabledata "Resource Unit of Measure" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Return Reason" = R,
                  tabledata "Return Receipt Header" = R,
                  tabledata "Return Receipt Line" = R,
                  tabledata "Sales Comment Line" = RIMD,
                  tabledata "Sales Discount Access" = R,
                  tabledata "Sales Header" = RIMD,
                  tabledata "Sales Header Archive" = RIMD,
                  tabledata "Sales Invoice Line" = R,
                  tabledata "Sales Line" = RIMD,
                  tabledata "Sales Line Archive" = RIMD,
#if not CLEAN21
                  tabledata "Sales Line Discount" = R,
#endif
                  tabledata "Sales Planning Line" = Rimd,
#if not CLEAN21
                  tabledata "Sales Price" = R,
#endif
                  tabledata "Sales Price Access" = R,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "Sales Shipment Line" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Ship-to Address" = R,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Standard Customer Sales Code" = R,
                  tabledata "Standard Sales Code" = R,
                  tabledata "Standard Sales Line" = R,
                  tabledata "Substitution Condition" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "To-do" = RM,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Unit of Measure Translation" = R,
                  tabledata "User Setup" = r,
                  tabledata "Value Entry" = Rm,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "Work Type" = R;
}
