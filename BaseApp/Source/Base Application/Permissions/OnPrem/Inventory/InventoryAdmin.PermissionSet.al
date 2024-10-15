permissionset 2928 "Inventory - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Inventory setup';

    Permissions = tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata Bin = RIMD,
                  tabledata "Customer Price Group" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Inventory Posting Group" = RIMD,
                  tabledata "Inventory Posting Setup" = RIMD,
                  tabledata "Inventory Setup" = RIMD,
                  tabledata "Item Category" = RIMD,
                  tabledata "Item Journal Batch" = RIMD,
                  tabledata "Item Journal Line" = MD,
                  tabledata "Item Journal Template" = RIMD,
                  tabledata "Item Tracking Code" = RIMD,
                  tabledata Location = RIMD,
                  tabledata Manufacturer = RIMD,
                  tabledata "Nonstock Item Setup" = RIMD,
                  tabledata "Order Promising Setup" = RIMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purchase Discount Access" = RIMD,
#if not CLEAN19
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
#endif
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata Purchasing = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Rounding Method" = RIMD,
                  tabledata "Sales Discount Access" = RIMD,
#if not CLEAN19
                  tabledata "Sales Line Discount" = RIMD,
#endif
                  tabledata "Shipping Agent" = RIMD,
                  tabledata "Shipping Agent Services" = RIMD,
                  tabledata "Social Listening Setup" = RIMD,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Transfer Route" = RIMD,
                  tabledata "Unit of Measure" = RIMD,
                  tabledata "Unit of Measure Translation" = RIMD,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "Warehouse Class" = RIMD;
}
