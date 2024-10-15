permissionset 9346 "Inventory - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read items/BOMs/SKUs/entries';

    Permissions = tabledata Bin = R,
                  tabledata "BOM Component" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = R,
                  tabledata "Item Cross Reference" = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Item Substitution" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = R,
                  tabledata "Nonstock Item" = R,
                  tabledata "Package No. Information" = R,
                  tabledata "Planning Component" = Rm,
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = RIMD,
                  tabledata "Production BOM Header" = R,
                  tabledata "Routing Header" = R,
                  tabledata "Serial No. Information" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Stockkeeping Unit Comment Line" = R,
                  tabledata "Substitution Condition" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri;
}
