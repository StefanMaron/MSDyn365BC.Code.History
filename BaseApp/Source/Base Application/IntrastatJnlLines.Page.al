page 12116 "Intrastat Jnl. Lines"
{
    Caption = 'Intrastat Jnl. Lines';
    Editable = false;
    PageType = Card;
    SourceTable = "Intrastat Jnl. Line";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("Reference Period"; "Reference Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference period.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the transaction.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a identification number that refers to the source document.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT registration number that is associated with the Intrastat journal.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name.';
                }
                field("Service Tariff No."; "Service Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the service tariff that is associated with the Intrastat journal.';
                }
                field("Payment Method"; "Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method that is associated with the Intrastat journal.';
                }
                field("Custom Office No."; "Custom Office No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs office that the trade of goods or services passes through.';
                }
                field("Corrected Intrastat Report No."; "Corrected Intrastat Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the corrected Intrastat report that is associated with the Intrastat journal.';
                }
                field("Corrected Document No."; "Corrected Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the corrected Intrastat journal entry.';
                }
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number.';
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country or region.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction that is the source of the entry.';
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the transport method used for the item on this line.';
                }
                field("Entry/Exit Point"; "Entry/Exit Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the point of entry or exit.';
                }
                field("Group Code"; "Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the group code that corresponds with the Intrastat journal.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area that the transaction takes place in.';
                }
                field("Supplementary Units"; "Supplementary Units")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you must report information about quantity and units of measure for this item.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity.';
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code that is associated with the Intrastat journal entry.';
                }
                field("Total Weight"; "Total Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the weight of items on the journal line based on the quantity and the net weight.';
                }
                field("Source Currency Amount"; "Source Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in the currency of the source of the transaction.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line amount.';
                }
                field("Statistical Value"; "Statistical Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that is calculated based on the amount on the journal line.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the original ledger entry.';
                }
                field("Source Entry No."; "Source Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original ledger entry.';
                }
                field("Cost Regulation %"; "Cost Regulation %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the regulation percent.';
                }
                field("Indirect Cost"; "Indirect Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the indirect cost amount.';
                }
                field("Internal Ref. No."; "Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal reference document.';
                }
            }
        }
    }

    actions
    {
    }
}

