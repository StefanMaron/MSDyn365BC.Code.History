page 11 "Shipment Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Shipment Methods';
    PageType = List;
    SourceTable = "Shipment Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the shipment method.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the shipment method.';
                }
                field("Intrastat Delivery Group Code"; "Intrastat Delivery Group Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the intrastat delivery group code.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Incl. Item Charges (Stat.Val.)"; "Incl. Item Charges (Stat.Val.)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies to include Intrastat amounts for value entries.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Adjustment %"; "Adjustment %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the adjustment percentage for the shipment method. This percentage is used to calculate an adjustment value for the Intrastat journal.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Include Item Charges (Amount)"; "Include Item Charges (Amount)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if intrastat amount of item ledger will be influenced by item charges  ';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
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
        area(processing)
        {
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Shipment Method Translations";
                RunPageLink = "Shipment Method" = FIELD(Code);
                ToolTip = 'Describe the shipment method in different languages. The translated descriptions appear on quotes, orders, invoices, and credit memos, based on the shipment method code and the language code on the document.';
            }
        }
    }
}

