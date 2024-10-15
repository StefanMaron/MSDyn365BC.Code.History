#if not CLEAN18
page 31060 "Intrastat Journal Lines"
{
    Caption = 'Intrastat Journal Lines (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Intrastat Jnl. Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220000)
            {
                ShowCaption = false;
                field("Declaration No."; "Declaration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration number for the Intrastat journal line';
                }
                field("Statistics Period"; "Statistics Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statistic period code for the Intrastat journal line.';
                }
                field("Statement Type"; "Statement Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a statement type for the Intrastat journal line.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of reverse charge lines';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date the item entry was posted.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number for the entry. To see the document numbers in the Item Ledger Entries window.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of export acc. Schedule';
                }
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the item''s tariff number.';
                }
                field("Statistic Indication"; "Statistic Indication")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statistic indication code for the item.';
                }
                field("Specific Movement"; "Specific Movement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the specific movement code for the item.';
                }
                field("Shpt. Method Code"; "Shpt. Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the shipment method for the shipment.';
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction type for the partner record. This information is used for Intrastat reporting.';
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Supplementary Units"; "Supplementary Units")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you must report information about quantity and units of measure for this item.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies quantity of item in intrastat journal lines';
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Total Weight"; "Total Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total weight for the items in the item entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the entry, excluding VAT.';
                }
                field("Statistical Value"; "Statistical Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s statistical value, which must be reported to the statistics authorities.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Source Entry No."; "Source Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the item entry had in the table it came from.';
                }
                field("Internal Ref. No."; "Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a reference number used by the customs and tax authorities.';
                }
            }
        }
    }

    actions
    {
    }
}


#endif