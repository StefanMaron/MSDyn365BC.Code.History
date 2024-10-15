namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Utilities;
using Microsoft.Inventory.Costing;
using Microsoft.Bank.Payment;
using Microsoft;
using Microsoft.Foundation.Company;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Intrastat;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.FinancialReports;
using Microsoft.Foundation.NoSeries;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.TransactionNature;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    Permissions = tabledata "ABI/CAB Codes" = RIMD,
                  tabledata "Activity Code" = RIMD,
                  tabledata "Appointment Code" = RIMD,
                  tabledata "Before Start Item Cost" = RIMD,
                  tabledata Bill = RIMD,
                  tabledata "Bill Posting Group" = RIMD,
                  tabledata "Blacklist Comm. Amount" = RIMD,
                  tabledata "Check Fiscal Code Setup" = RIMD,
                  tabledata "Company Officials" = RIMD,
                  tabledata "Company Types" = RIMD,
                  tabledata "Compress Depreciation" = RIMD,
                  tabledata "Computed Contribution" = RIMD,
                  tabledata "Computed Withholding Tax" = RIMD,
                  tabledata "Contribution Bracket" = RIMD,
                  tabledata "Contribution Bracket Line" = RIMD,
                  tabledata "Contribution Code" = RIMD,
                  tabledata "Contribution Code Line" = RIMD,
                  tabledata "Contribution Payment" = RIMD,
                  tabledata Contributions = RIMD,
                  tabledata "Customer Bill Header" = RIMD,
                  tabledata "Customer Bill Line" = RIMD,
                  tabledata "Customs Authority Vendor" = RIMD,
                  tabledata "Customs Office" = RIMD,
                  tabledata "Deferring Due Dates" = RIMD,
                  tabledata "Document Relation" = RIMD,
                  tabledata "Fattura Code" = RIMD,
                  tabledata "Fattura Document Type" = RIMD,
                  tabledata "Fattura Header" = RIMD,
                  tabledata "Fattura Line" = RIMD,
                  tabledata "Fattura Project Info" = RIMD,
                  tabledata "Fattura Setup" = RIMD,
                  tabledata "Fixed Due Dates" = RIMD,
                  tabledata "GL Book Entry" = RIMD,
                  tabledata "Goods Appearance" = RIMD,
                  tabledata "Incl. in VAT Report Error Log" = RIMD,
                  tabledata "Interest on Arrears" = RIMD,
#if not CLEAN22
                  tabledata "Intra - form Buffer" = RIMD,
#endif
                  tabledata "Issued Customer Bill Header" = RIMD,
                  tabledata "Issued Customer Bill Line" = RIMD,
                  tabledata "Item Cost History" = RIMD,
                  tabledata "Item Costing Setup" = RIMD,
                  tabledata "Lifo Band" = RIMD,
                  tabledata "Lifo Category" = RIMD,
                  tabledata "No. Series Line Purchase" = RIMD,
                  tabledata "No. Series Line Sales" = RIMD,
                  tabledata "Payment Lines" = RIMD,
                  tabledata "Periodic Settlement VAT Entry" = RIMD,
                  tabledata "Posted Payment Lines" = RIMD,
                  tabledata "Posted Vendor Bill Header" = RIMD,
                  tabledata "Posted Vendor Bill Line" = RIMD,
                  tabledata "Purch. Withh. Contribution" = RIMD,
                  tabledata "Reprint Info Fiscal Reports" = RIMD,
                  tabledata "Service Tariff Number" = RIMD,
                  tabledata "Spesometro Appointment" = RIMD,
                  tabledata "Subcontractor Prices" = RIMD,
                  tabledata "Tmp Withholding Contribution" = RIMD,
                  tabledata "Transport Reason Code" = RIMD,
                  tabledata "VAT Book Entry" = RIMD,
                  tabledata "VAT Exemption" = RIMD,
                  tabledata "VAT Identifier" = RIMD,
                  tabledata "VAT Plafond Period" = RIMD,
                  tabledata "VAT Register - Buffer" = RIMD,
                  tabledata "VAT Register" = RIMD,
                  tabledata "VAT Transaction Nature" = RIMD,
                  tabledata "VAT Transaction Report Amount" = RIMD,
                  tabledata "Vendor Bill Header" = RIMD,
                  tabledata "Vendor Bill Line" = RIMD,
                  tabledata "Vendor Bill Withholding Tax" = RIMD,
                  tabledata "Withhold Code" = RIMD,
                  tabledata "Withhold Code Line" = RIMD,
                  tabledata "Withholding Tax" = RIMD,
                  tabledata "Withholding Tax Line" = RIMD,
                  tabledata "Withholding Tax Payment" = RIMD,
                  tabledata "Withholding Exceptional Event" = RIMD;
}
