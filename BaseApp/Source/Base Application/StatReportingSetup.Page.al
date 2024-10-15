#if not CLEAN18
page 31065 "Stat. Reporting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statutory Reporting Setup (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Stat. Reporting Setup";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            group(VIES)
            {
                Caption = 'VIES';
                Visible = false;
            }
            group(Intrastat)
            {
                Caption = 'Intrastat';
                field("Transaction Type Mandatory"; "Transaction Type Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this option to make transaction type Specifiesion mandatory.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Transaction Spec. Mandatory"; "Transaction Spec. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you are using a mandatory transaction specification for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Transport Method Mandatory"; "Transport Method Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this option to make transport method Specifiesion mandatory.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Shipment Method Mandatory"; "Shipment Method Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this option to make schipment method Specifiesion mandatory.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Tariff No. Mandatory"; "Tariff No. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this option to make tariff number Specifiesion mandatory.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Net Weight Mandatory"; "Net Weight Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibility to select intrastat item''s net weight.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Country/Region of Origin Mand."; "Country/Region of Origin Mand.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to determine the item''s country/region of origin information.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("No Item Charges in Intrastat"; "No Item Charges in Intrastat")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether item charges will be included in Intrastat reports. Select this option if no item charges will be included.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Customs Office No."; "Customs Office No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customs office.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Customs Office Name"; "Customs Office Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of customs office.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Intrastat Export Object Type"; "Intrastat Export Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of intrastat export object.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field is discontinued. Use Intrastat Jnl. Line event OnBeforeExportIntrastatJournalCZL to change export means.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Intrastat Export Object No."; "Intrastat Export Object No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of intrastat export object.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field is discontinued. Use Intrastat Jnl. Line event OnBeforeExportIntrastatJournalCZL to change export means.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Intrastat Exch.Rate Mandatory"; "Intrastat Exch.Rate Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibility to select intrastat exchange rate.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Ignore Intrastat Ex.Rate From"; "Ignore Intrastat Ex.Rate From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which changed the method of converting amounts in foreign currency. Amounts of invoices and credit memos will be converted by currency factor of related VAT entry. For amounts of receipts and shipments will be used amounts from related value entry without conversion.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Get Tariff No. From"; "Get Tariff No. From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to determine the item''s tariff number. Option: item card or posted entries.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Get Net Weight From"; "Get Net Weight From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to determine the item''s net weight. Option: item card or posted entries.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Get Country/Region of Origin"; "Get Country/Region of Origin")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to determine the item''s country/region of origin information.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Intrastat Rounding Type"; "Intrastat Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of rounding.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Intrastat Declaration Nos."; "Intrastat Declaration Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies declaration number series of intrastat.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Stat. Value Reporting"; "Stat. Value Reporting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the information for intrastat.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Cost Regulation %"; "Cost Regulation %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the information for intrastat.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Include other Period add.Costs"; "Include other Period add.Costs")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the information for intrastat.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
            }
            group("VAT Statement")
            {
                Caption = 'VAT Statement';
            }
            group("Company Official")
            {
                Caption = 'Company Official';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}
#endif