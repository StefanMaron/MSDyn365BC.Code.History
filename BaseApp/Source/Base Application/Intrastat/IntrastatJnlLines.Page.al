#if not CLEAN22
page 12116 "Intrastat Jnl. Lines"
{
    Caption = 'Intrastat Jnl. Lines';
    Editable = false;
    PageType = Card;
    SourceTable = "Intrastat Jnl. Line";
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moving to Intrastat extension.';

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("Reference Period"; Rec."Reference Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference period.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the transaction.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a identification number that refers to the source document.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT registration number that is associated with the Intrastat journal.';
                    Visible = false;
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name.';
                }
                field("Service Tariff No."; Rec."Service Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the service tariff that is associated with the Intrastat journal.';
                }
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method that is associated with the Intrastat journal.';
                }
                field("Custom Office No."; Rec."Custom Office No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs office that the trade of goods or services passes through.';
                }
                field("Corrected Intrastat Report No."; Rec."Corrected Intrastat Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the corrected Intrastat report that is associated with the Intrastat journal.';
                }
                field("Corrected Document No."; Rec."Corrected Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the corrected Intrastat journal entry.';
                }
                field("Tariff No."; Rec."Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country or region.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction that is the source of the entry.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the transport method used for the item on this line.';
                }
                field("Entry/Exit Point"; Rec."Entry/Exit Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the point of entry or exit.';
                }
                field("Group Code"; Rec."Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the group code that corresponds with the Intrastat journal.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area that the transaction takes place in.';
                }
                field("Supplementary Units"; Rec."Supplementary Units")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you must report information about quantity and units of measure for this item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code that is associated with the Intrastat journal entry.';
                }
                field("Total Weight"; Rec."Total Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the weight of items on the journal line based on the quantity and the net weight.';
                }
                field("Source Currency Amount"; Rec."Source Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in the currency of the source of the transaction.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line amount.';
                }
                field("Statistical Value"; Rec."Statistical Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that is calculated based on the amount on the journal line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the original ledger entry.';
                }
                field("Source Entry No."; Rec."Source Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original ledger entry.';
                }
                field("Cost Regulation %"; Rec."Cost Regulation %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the regulation percent.';
                }
                field("Indirect Cost"; Rec."Indirect Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the indirect cost amount.';
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
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
#endif