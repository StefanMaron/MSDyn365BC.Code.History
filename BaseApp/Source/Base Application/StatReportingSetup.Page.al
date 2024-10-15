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
                field("Tax Office Number"; "Tax Office Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax office number for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Tax Office Region Number"; "Tax Office Region Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax office region number for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Decl. Auth. Employee No."; "VIES Decl. Auth. Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for VIES declaration.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Decl. Filled by Empl. No."; "VIES Decl. Filled by Empl. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for VIES declaration.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Natural Employee No."; "Natural Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the numbor of natural employee for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Declaration Nos."; "VIES Declaration Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for VIES Declaration.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Taxpayer Type"; "Taxpayer Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies tax payer type.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech field Company Type.';
                    ObsoleteTag = '17.5';
                    Visible = false;
                }
                field("Tax Payer Status"; "Tax Payer Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies tax payer status.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Main Economic Activity I Code"; "Main Economic Activity I Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the main economic activity code for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Main Economic Activity I Desc."; "Main Economic Activity I Desc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the main economic activity description for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Number of Lines"; "VIES Number of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines for VIES declaration.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Declaration Report No."; "VIES Declaration Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object number for VIES declaration report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Declaration Report Name"; "VIES Declaration Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object name for VIES declaration report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Decl. Exp. Obj. Type"; "VIES Decl. Exp. Obj. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object type for VIES declaration export.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Decl. Exp. Obj. No."; "VIES Decl. Exp. Obj. No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object number for VIES declaration export.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VIES Decl. Exp. Obj. Name"; "VIES Decl. Exp. Obj. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object name for VIES declaration export.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Municipality No."; "Municipality No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the municipality number fot the tax office that receives the VIES declaration or VAT control report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field(Street; Street)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies street.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("House No."; "House No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s house number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Apartment No."; "Apartment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies apartment number.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Organizational Unit Code"; "Organizational Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type organizational unit code for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This unused field is discontinued and will be removed.';
                    ObsoleteTag = '17.5';
                    Visible = false;
                }
                field("Company Trade Name"; "Company Trade Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Company Trade Name Appendix"; "Company Trade Name Appendix")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies type of the company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
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
                field("Area Code"; "Area Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area code.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This unused field is discontinued and will be removed.';
                    ObsoleteTag = '17.5';
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
                field("VAT Stat. Auth.Employee No."; "VAT Stat. Auth.Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for VAT reports.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Stat. Filled by Empl. No."; "VAT Stat. Filled by Empl. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee number for VAT reports.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Statement Country Name"; "VAT Statement Country Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country name for VAT statements.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Control Report Xml Format"; "VAT Control Report Xml Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default xml format for VAT control report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Control Report Nos."; "VAT Control Report Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series for VAT control report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Simplified Tax Document Limit"; "Simplified Tax Document Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value for simplified fax document for VAT control report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Data Box ID"; "Data Box ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of certain data box.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Control Report E-mail"; "VAT Control Report E-mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email address for VAT control report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
            }
            group("Company Official")
            {
                Caption = 'Company Official';
                field("Official Code"; "Official Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official Type"; "Official Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official Name"; "Official Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official First Name"; "Official First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official Surname"; "Official Surname")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surname of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official Birth Date"; "Official Birth Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the birth date of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official Reg.No.of Tax Adviser"; "Official Reg.No.of Tax Adviser")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Official Registration No."; "Official Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of official company for reporting.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
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

