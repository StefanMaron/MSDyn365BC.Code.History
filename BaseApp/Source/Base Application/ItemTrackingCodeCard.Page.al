page 6512 "Item Tracking Code Card"
{
    Caption = 'Item Tracking Code Card';
    PageType = Card;
    SourceTable = "Item Tracking Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the item tracking code.';
                }
            }
            group("Serial No.")
            {
                Caption = 'Serial No.';
                group(Control64)
                {
                    Caption = 'General';
                    field("SN Specific Tracking"; "SN Specific Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that when handling an outbound unit of the item in question, you must always specify which existing serial number to handle.';
                    }
                }
                group(Inbound)
                {
                    Caption = 'Inbound';
                    field("SN Info. Inbound Must Exist"; "SN Info. Inbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN No. Info. Must Exist';
                        ToolTip = 'Specifies that serial numbers on inbound document lines must have an information record in the Serial No. Information Card.';
                    }
                    field("SN Purchase Inbound Tracking"; "SN Purchase Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Purchase Tracking';
                        ToolTip = 'Specifies that inbound purchase document lines require serial numbers.';
                    }
                    field("SN Sales Inbound Tracking"; "SN Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Sales Tracking';
                        ToolTip = 'Specifies that inbound sales document lines require serial numbers.';
                    }
                    field("SN Pos. Adjmt. Inb. Tracking"; "SN Pos. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type positive entry require serial numbers.';
                    }
                    field("SN Neg. Adjmt. Inb. Tracking"; "SN Neg. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type negative entry require serial numbers.';
                    }
                    field("SN Assembly Inbound Tracking"; "SN Assembly Inbound Tracking")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'SN Assembly Tracking';
                        ToolTip = 'Specifies that serial numbers are required with inbound posting from assembly orders.';
                    }
                    field("SN Manuf. Inbound Tracking"; "SN Manuf. Inbound Tracking")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'SN Manufacturing Tracking';
                        ToolTip = 'Specifies that serial numbers are required with inbound posting from production - typically output.';
                    }
                }
                group(Control82)
                {
                    ShowCaption = false;
                    field("SN Warehouse Tracking"; "SN Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Warehouse Tracking';
                        ToolTip = 'Specifies that warehouse document lines require serial numbers.';
                    }
                    field("SN Transfer Tracking"; "SN Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Transfer Tracking';
                        ToolTip = 'Specifies that transfer order lines require serial numbers.';
                    }
                }
                group(Outbound)
                {
                    Caption = 'Outbound';
                    field("SN Info. Outbound Must Exist"; "SN Info. Outbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN No. Info. Must Exist';
                        ToolTip = 'Specifies that serial numbers on outbound document lines must have an information record in the Serial No. Information Card.';
                    }
                    field("SN Purchase Outbound Tracking"; "SN Purchase Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Purchase Tracking';
                        ToolTip = 'Specifies that outbound purchase document lines require serial numbers.';
                    }
                    field("SN Sales Outbound Tracking"; "SN Sales Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Sales Tracking';
                        ToolTip = 'Specifies that outbound sales document lines require serial numbers.';
                    }
                    field("SN Pos. Adjmt. Outb. Tracking"; "SN Pos. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type positive entry require serial numbers.';
                    }
                    field("SN Neg. Adjmt. Outb. Tracking"; "SN Neg. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'SN Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type negative entry require serial numbers.';
                    }
                    field("SN Assembly Outbound Tracking"; "SN Assembly Outbound Tracking")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'SN Assembly Tracking';
                        ToolTip = 'Specifies that serial numbers are required with outbound posting from assembly orders.';
                    }
                    field("SN Manuf. Outbound Tracking"; "SN Manuf. Outbound Tracking")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'SN Manufacturing Tracking';
                        ToolTip = 'Specifies that serial numbers are required with outbound posting from production - typically consumption.';
                    }
                }
            }
            group("Lot No.")
            {
                Caption = 'Lot No.';
                group(Control74)
                {
                    Caption = 'General';
                    field("Lot Specific Tracking"; "Lot Specific Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        ToolTip = 'Specifies that when handling an outbound unit, always specify which existing lot number to handle.';
                    }
                }
                group(Control47)
                {
                    Caption = 'Inbound';
                    field("Lot Info. Inbound Must Exist"; "Lot Info. Inbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot No. Info. Must Exist';
                        ToolTip = 'Specifies that lot numbers on inbound document lines must have an information record in the Lot No. Information Card.';
                    }
                    field("Lot Purchase Inbound Tracking"; "Lot Purchase Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Purchase Tracking';
                        ToolTip = 'Specifies that inbound purchase document lines require a lot number.';
                    }
                    field("Lot Sales Inbound Tracking"; "Lot Sales Inbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Sales Tracking';
                        ToolTip = 'Specifies that inbound sales document lines require a lot number.';
                    }
                    field("Lot Pos. Adjmt. Inb. Tracking"; "Lot Pos. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type positive entry require a lot number.';
                    }
                    field("Lot Neg. Adjmt. Inb. Tracking"; "Lot Neg. Adjmt. Inb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that inbound item journal lines of type negative entry require a lot number.';
                    }
                    field("Lot Assembly Inbound Tracking"; "Lot Assembly Inbound Tracking")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Lot Assembly Tracking';
                        ToolTip = 'Specifies that lot numbers are required with inbound posting from assembly orders.';
                    }
                    field("Lot Manuf. Inbound Tracking"; "Lot Manuf. Inbound Tracking")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Lot Manufacturing Tracking';
                        ToolTip = 'Specifies that lot numbers are required with outbound posting from production - typically output.';
                    }
                }
                group(Control81)
                {
                    ShowCaption = false;
                    field("Lot Warehouse Tracking"; "Lot Warehouse Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Warehouse Tracking';
                        ToolTip = 'Specifies that warehouse document lines require a lot number.';
                    }
                    field("Lot Transfer Tracking"; "Lot Transfer Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Transfer Tracking';
                        ToolTip = 'Specifies that transfer order lines require a lot number.';
                    }
                }
                group(Control48)
                {
                    Caption = 'Outbound';
                    field("Lot Info. Outbound Must Exist"; "Lot Info. Outbound Must Exist")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot No. Info. Must Exist';
                        ToolTip = 'Specifies that lot numbers on outbound document lines must have an information record in the Lot No. Information Card.';
                    }
                    field("Lot Purchase Outbound Tracking"; "Lot Purchase Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Purchase Tracking';
                        ToolTip = 'Specifies that outbound purchase document lines require a lot number.';
                    }
                    field("Lot Sales Outbound Tracking"; "Lot Sales Outbound Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Sales Tracking';
                        ToolTip = 'Specifies that outbound sales document lines require a lot number.';
                    }
                    field("Lot Pos. Adjmt. Outb. Tracking"; "Lot Pos. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Positive Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type positive entry require a lot number.';
                    }
                    field("Lot Neg. Adjmt. Outb. Tracking"; "Lot Neg. Adjmt. Outb. Tracking")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot Negative Adjmt. Tracking';
                        ToolTip = 'Specifies that outbound item journal lines of type negative entry require a lot number.';
                    }
                    field("Lot Assembly Outbound Tracking"; "Lot Assembly Outbound Tracking")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Lot Assembly Tracking';
                        ToolTip = 'Specifies that lot numbers are required with outbound posting from assembly orders.';
                    }
                    field("Lot Manuf. Outbound Tracking"; "Lot Manuf. Outbound Tracking")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Lot Manufacturing Tracking';
                        ToolTip = 'Specifies that lot numbers are required with outbound posting from production - typically consumption.';
                    }
                }
            }
            group("Misc.")
            {
                Caption = 'Misc.';
                field("Warranty Date Formula"; "Warranty Date Formula")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the formula that calculates the warranty date entered in the Warranty Date field on item tracking line.';
                }
                field("Man. Warranty Date Entry Reqd."; "Man. Warranty Date Entry Reqd.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that a warranty date must be entered manually.';
                }
                field("Use Expiration Dates"; "Use Expiration Dates")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that items that use this item tracking code can have an expiration date. This will enable checks for expiration dates, which can affect performance for documents with many Item Tracking Lines.';

                    trigger OnValidate()
                    begin
                        ManExpirDateEntryReqdEditable := "Use Expiration Dates";
                        StrictExpirationPostingEditable := "Use Expiration Dates";
                    end;
                }
                field("Man. Expir. Date Entry Reqd."; "Man. Expir. Date Entry Reqd.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Require Expiration Dates';
                    Editable = ManExpirDateEntryReqdEditable;
                    ToolTip = 'Specifies that items that use this item tracking code must have expiration dates.';
                }
                field("Strict Expiration Posting"; "Strict Expiration Posting")
                {
                    ApplicationArea = ItemTracking;
                    Editable = StrictExpirationPostingEditable;
                    ToolTip = 'Specifies if the expiration date is considered when you sell items. For example, you cannot post a sales order for an item that has passed its expiration date.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ManExpirDateEntryReqdEditable := "Use Expiration Dates";
        StrictExpirationPostingEditable := "Use Expiration Dates";
    end;

    var
        StrictExpirationPostingEditable: Boolean;
        ManExpirDateEntryReqdEditable: Boolean;
}

