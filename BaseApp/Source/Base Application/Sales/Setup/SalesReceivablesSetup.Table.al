namespace Microsoft.Sales.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Warehouse.Structure;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using System.Environment;
#if not CLEAN23
using System.Environment.Configuration;
using System.Telemetry;
#endif
using System.Threading;

table 311 "Sales & Receivables Setup"
{
    Caption = 'Sales & Receivables Setup';
    DrillDownPageID = "Sales & Receivables Setup";
    LookupPageID = "Sales & Receivables Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Discount Posting"; Option)
        {
            Caption = 'Discount Posting';
            OptionCaption = 'No Discounts,Invoice Discounts,Line Discounts,All Discounts';
            OptionMembers = "No Discounts","Invoice Discounts","Line Discounts","All Discounts";

            trigger OnValidate()
            var
                DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
            begin
                DiscountNotificationMgt.NotifyAboutMissingSetup(RecordId, '', "Discount Posting", 0);
            end;
        }
        field(4; "Credit Warnings"; Option)
        {
            Caption = 'Credit Warnings';
            OptionCaption = 'Both Warnings,Credit Limit,Overdue Balance,No Warning';
            OptionMembers = "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        }
        field(5; "Stockout Warning"; Boolean)
        {
            Caption = 'Stockout Warning';
            InitValue = true;
        }
        field(6; "Shipment on Invoice"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipment on Invoice';
        }
        field(7; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
        }
        field(8; "Ext. Doc. No. Mandatory"; Boolean)
        {
            Caption = 'Ext. Doc. No. Mandatory';
        }
        field(9; "Customer Nos."; Code[20])
        {
            Caption = 'Customer Nos.';
            TableRelation = "No. Series";
        }
        field(10; "Quote Nos."; Code[20])
        {
            Caption = 'Quote Nos.';
            TableRelation = "No. Series";
        }
        field(11; "Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order Nos.';
            TableRelation = "No. Series";
        }
        field(12; "Invoice Nos."; Code[20])
        {
            Caption = 'Invoice Nos.';
            TableRelation = "No. Series";
        }
        field(13; "Posted Invoice Nos."; Code[20])
        {
            Caption = 'Posted Invoice Nos.';
            TableRelation = "No. Series";
        }
        field(14; "Credit Memo Nos."; Code[20])
        {
            Caption = 'Credit Memo Nos.';
            TableRelation = "No. Series";
        }
        field(15; "Posted Credit Memo Nos."; Code[20])
        {
            Caption = 'Posted Credit Memo Nos.';
            TableRelation = "No. Series";
        }
        field(16; "Posted Shipment Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Posted Shipment Nos.';
            TableRelation = "No. Series";
        }
        field(17; "Reminder Nos."; Code[20])
        {
            Caption = 'Reminder Nos.';
            TableRelation = "No. Series";
        }
        field(18; "Issued Reminder Nos."; Code[20])
        {
            Caption = 'Issued Reminder Nos.';
            TableRelation = "No. Series";
        }
        field(19; "Fin. Chrg. Memo Nos."; Code[20])
        {
            Caption = 'Fin. Chrg. Memo Nos.';
            TableRelation = "No. Series";
        }
        field(20; "Issued Fin. Chrg. M. Nos."; Code[20])
        {
            Caption = 'Issued Fin. Chrg. M. Nos.';
            TableRelation = "No. Series";
        }
        field(21; "Posted Prepmt. Inv. Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Inv. Nos.';
            TableRelation = "No. Series";
        }
        field(22; "Posted Prepmt. Cr. Memo Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Cr. Memo Nos.';
            TableRelation = "No. Series";
        }
        field(23; "Blanket Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Blanket Order Nos.';
            TableRelation = "No. Series";
        }
        field(24; "Calc. Inv. Discount"; Boolean)
        {
            Caption = 'Calc. Inv. Discount';
        }
        field(25; "Appln. between Currencies"; Option)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Appln. between Currencies';
            OptionCaption = 'None,EMU,All';
            OptionMembers = "None",EMU,All;
        }
        field(26; "Copy Comments Blanket to Order"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Copy Comments Blanket to Order';
            InitValue = true;
        }
        field(27; "Copy Comments Order to Invoice"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Copy Comments Order to Invoice';
            InitValue = true;
        }
        field(28; "Copy Comments Order to Shpt."; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Copy Comments Order to Shpt.';
            InitValue = true;
        }
        field(29; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';
        }
        field(30; "Calc. Inv. Disc. per VAT ID"; Boolean)
        {
            Caption = 'Calc. Inv. Disc. per VAT ID';
        }
        field(31; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(32; "Check Prepmt. when Posting"; Boolean)
        {
            Caption = 'Check Prepmt. when Posting';
        }
        field(33; "Prepmt. Auto Update Frequency"; Option)
        {
            Caption = 'Prepmt. Auto Update Frequency';
            DataClassification = SystemMetadata;
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;

            trigger OnValidate()
            var
                PrepaymentMgt: Codeunit "Prepayment Mgt.";
            begin
                if "Prepmt. Auto Update Frequency" = xRec."Prepmt. Auto Update Frequency" then
                    exit;

                PrepaymentMgt.CreateAndStartJobQueueEntrySales("Prepmt. Auto Update Frequency");
            end;
        }
        field(35; "Default Posting Date"; Enum "Default Posting Date")
        {
            Caption = 'Default Posting Date';
        }
        field(36; "Default Quantity to Ship"; Option)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Default Quantity to Ship';
            OptionCaption = 'Remainder,Blank';
            OptionMembers = Remainder,Blank;
        }
        field(37; "Archive Quotes and Orders"; Boolean)
        {
            Caption = 'Archive Quotes and Orders';
            ObsoleteReason = 'Replaced by new fields Archive Quotes and Archive Orders';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(38; "Post with Job Queue"; Boolean)
        {
            Caption = 'Post with Job Queue';

            trigger OnValidate()
            begin
                if not "Post with Job Queue" then
                    "Post & Print with Job Queue" := false;
            end;
        }
        field(39; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            TableRelation = "Job Queue Category";
        }
        field(40; "Job Queue Priority for Post"; Integer)
        {
            Caption = 'Job Queue Priority for Post';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(JobQueuePriorityErr);
            end;
        }
        field(41; "Post & Print with Job Queue"; Boolean)
        {
            Caption = 'Post & Print with Job Queue';

            trigger OnValidate()
            begin
                if "Post & Print with Job Queue" then
                    "Post with Job Queue" := true;
            end;
        }
        field(42; "Job Q. Prio. for Post & Print"; Integer)
        {
            Caption = 'Job Q. Prio. for Post & Print';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(JobQueuePriorityErr);
            end;
        }
        field(43; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
        }
        field(44; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
        }
        field(45; "Direct Debit Mandate Nos."; Code[20])
        {
            Caption = 'Direct Debit Mandate Nos.';
            TableRelation = "No. Series";
        }
        field(46; "Allow Document Deletion Before"; Date)
        {
            Caption = 'Allow Document Deletion Before';
        }
        field(47; "Report Output Type"; Enum "Setup Report Output Type")
        {
            Caption = 'Report Output Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS() then
                        TestField("Report Output Type", "Report Output Type"::PDF);
            end;
        }
        field(49; "Document Default Line Type"; Enum "Sales Line Type")
        {
            Caption = 'Document Default Line Type';
        }
        field(50; "Default Item Quantity"; Boolean)
        {
            Caption = 'Default Item Quantity';
        }
        field(51; "Create Item from Description"; Boolean)
        {
            Caption = 'Create Item from Description';
        }
        field(52; "Archive Quotes"; Option)
        {
            Caption = 'Archive Quotes';
            OptionCaption = 'Never,Question,Always';
            OptionMembers = Never,Question,Always;
        }
        field(53; "Archive Orders"; Boolean)
        {
            Caption = 'Archive Orders';

            trigger OnValidate()
            var
                CRMConnectionSetup: Record "CRM Connection Setup";
            begin
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    Error(CRMBidirectionalSalesOrderIntEnabledErr);
            end;
        }
        field(54; "Archive Blanket Orders"; Boolean)
        {
            Caption = 'Archive Blanket Orders';
        }
        field(55; "Archive Return Orders"; Boolean)
        {
            Caption = 'Archive Return Orders';
        }
        field(56; "Default G/L Account Quantity"; Boolean)
        {
            Caption = 'Default G/L Account Quantity';
        }
        field(57; "Create Item from Item No."; Boolean)
        {
            Caption = 'Create Item from Item No.';
        }
        field(58; "Copy Customer Name to Entries"; Boolean)
        {
            Caption = 'Copy Customer Name to Entries';

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
            begin
                if "Copy Customer Name to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(60; "Batch Archiving Quotes"; Boolean)
        {
            Caption = 'Batch Archiving Quotes';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
            ObsoleteReason = 'The field is part of the removed functionality.';
        }
        field(61; "Ignore Updated Addresses"; Boolean)
        {
            Caption = 'Ignore Updated Addresses';
        }
        field(65; "Skip Manual Reservation"; Boolean)
        {
            Caption = 'Skip Manual Reservation';
            DataClassification = SystemMetadata;
        }
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            DataClassification = SystemMetadata;
        }
        field(170; "Insert Std. Sales Lines Mode"; Option)
        {
            Caption = 'Insert Std. Sales Lines Mode';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
            ObsoleteTag = '18.0';
        }
        field(171; "Insert Std. Lines on Quotes"; Boolean)
        {
            Caption = 'Insert Std. Lines on Quotes';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(172; "Insert Std. Lines on Orders"; Boolean)
        {
            Caption = 'Insert Std. Lines on Orders';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(173; "Insert Std. Lines on Invoices"; Boolean)
        {
            Caption = 'Insert Std. Lines on Invoices';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(174; "Insert Std. Lines on Cr. Memos"; Boolean)
        {
            Caption = 'Insert Std. Lines on Cr. Memos';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;

            trigger OnValidate()
#if not CLEAN23
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
                FeatureKeyManagement: Codeunit "Feature Key Management";
#endif
            begin
#if not CLEAN23
                if "Allow Multiple Posting Groups" then
                    FeatureTelemetry.LogUptake(
                        '0000JRB', FeatureKeyManagement.GetAllowMultipleCustVendPostingGroupsFeatureKey(), Enum::"Feature Uptake Status"::Discovered);
#endif
            end;
        }
        field(176; "Check Multiple Posting Groups"; enum "Posting Group Change Method")
        {
            Caption = 'Check Multiple Posting Groups';
            DataClassification = SystemMetadata;
        }
        field(200; "Quote Validity Calculation"; DateFormula)
        {
            Caption = 'Quote Validity Calculation';
            DataClassification = SystemMetadata;
        }
        field(201; "S. Invoice Template Name"; Code[10])
        {
            Caption = 'Sales Invoice Journal Template';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(202; "S. Cr. Memo Template Name"; Code[10])
        {
            Caption = 'Sales Cr. Memo Journal Template';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(203; "S. Prep. Inv. Template Name"; Code[10])
        {
            Caption = 'Sales Prep. Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(204; "S. Prep. Cr.Memo Template Name"; Code[10])
        {
            Caption = 'Sales Prep. Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(205; "IC Sales Invoice Template Name"; Code[10])
        {
            Caption = 'IC Sales Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        field(206; "IC Sales Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Sales Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        field(207; "Fin. Charge Jnl. Template Name"; Code[10])
        {
            Caption = 'Finance Charge Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(208; "Reminder Journal Template Name"; Code[10])
        {
            Caption = 'Reminder Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(209; "Reminder Journal Batch Name"; Code[10])
        {
            Caption = 'Reminder Journal Batch Name';
            TableRelation = if ("Reminder Journal Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Reminder Journal Template Name"));

            trigger OnValidate()
            begin
                TestField("Reminder Journal Template Name");
            end;
        }
        field(210; "Copy Line Descr. to G/L Entry"; Boolean)
        {
            Caption = 'Copy Line Descr. to G/L Entry';
            DataClassification = SystemMetadata;
        }
        field(211; "Fin. Charge Jnl. Batch Name"; Code[10])
        {
            Caption = 'Finance Charge Journal Batch Name';
            TableRelation = if ("Fin. Charge Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Fin. Charge Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Fin. Charge Jnl. Template Name");
            end;
        }
        field(393; "Canceled Issued Reminder Nos."; Code[20])
        {
            Caption = 'Canceled Issued Reminder Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(395; "Canc. Iss. Fin. Ch. Mem. Nos."; Code[20])
        {
            Caption = 'Canceled Issued Fin. Charge Memo Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(810; "Invoice Posting Setup"; Enum "Sales Invoice Posting")
        {
            Caption = 'Invoice Posting Setup';
            ObsoleteReason = 'Replaced by direct selection of posting interface in codeunits.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(5329; "Write-in Product Type"; Option)
        {
            Caption = 'Write-in Product Type';
            OptionCaption = 'Item,Resource';
            OptionMembers = Item,Resource;
        }
        field(5330; "Write-in Product No."; Code[20])
        {
            Caption = 'Write-in Product No.';
            TableRelation = if ("Write-in Product Type" = const(Item)) Item."No." where(Type = filter(Service | "Non-Inventory"))
            else
            if ("Write-in Product Type" = const(Resource)) Resource."No.";

            trigger OnValidate()
            var
                Item: Record Item;
                Resource: Record Resource;
                CRMIntegrationRecord: Record "CRM Integration Record";
                CRMProductName: Codeunit "CRM Product Name";
                RecId: RecordId;
            begin
                case "Write-in Product Type" of
                    "Write-in Product Type"::Item:
                        begin
                            if not Item.Get("Write-in Product No.") then
                                exit;
                            RecId := Item.RecordId();
                        end;
                    "Write-in Product Type"::Resource:
                        begin
                            if not Resource.Get("Write-in Product No.") then
                                exit;
                            RecId := Resource.RecordId();
                        end;
                end;
                if CRMIntegrationRecord.FindByRecordID(RecId) then
                    Error(ProductCoupledErr, CRMProductName.Short());
            end;
        }
        field(5775; "Auto Post Non-Invt. via Whse."; Enum "Non-Invt. Item Whse. Policy")
        {
            Caption = 'Auto Post Non-Invt. via Whse.';
        }
        field(5800; "Posted Return Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Posted Return Receipt Nos.';
            TableRelation = "No. Series";
        }
        field(5801; "Copy Cmts Ret.Ord. to Ret.Rcpt"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Ret.Rcpt';
            InitValue = true;
        }
        field(5802; "Copy Cmts Ret.Ord. to Cr. Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Cr. Memo';
            InitValue = true;
        }
        field(6600; "Return Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Order Nos.';
            TableRelation = "No. Series";
        }
        field(6601; "Return Receipt on Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Receipt on Credit Memo';
        }
        field(6602; "Exact Cost Reversing Mandatory"; Boolean)
        {
            Caption = 'Exact Cost Reversing Mandatory';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            InitValue = "Lowest Price";

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Sale);
            end;
        }
        field(7001; "Price List Nos."; Code[20])
        {
            Caption = 'Price List Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(7002; "Allow Editing Active Price"; Boolean)
        {
            Caption = 'Allow Editing Active Price';
            DataClassification = SystemMetadata;
        }
        field(7003; "Default Price List Code"; Code[20])
        {
            Caption = 'Default Price List Code';
            TableRelation = "Price List Header" where("Price Type" = const(Sale), "Source Group" = const(Customer), "Allow Updating Defaults" = const(true));
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                    PriceListHeader.TestField("Allow Updating Defaults");
                    Validate("Default Price List Code", PriceListHeader.Code);
                end;
            end;
#if not CLEAN23

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
            begin
                if ("Default Price List Code" <> xRec."Default Price List Code") or (CurrFieldNo = 0) then
                    FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
            end;
#endif
        }
        field(7005; "Use Customized Lookup"; Boolean)
        {
            Caption = 'Use Your Custom Lookup';
            DataClassification = SystemMetadata;
        }
        field(7101; "Customer Group Dimension Code"; Code[20])
        {
            Caption = 'Customer Group Dimension Code';
            TableRelation = Dimension;
        }
        field(7102; "Salesperson Dimension Code"; Code[20])
        {
            Caption = 'Salesperson Dimension Code';
            TableRelation = Dimension;
        }
        field(7103; "Freight G/L Acc. No."; Code[20])
        {
            Caption = 'Freight G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAccPostingTypeBlockedAndGenProdPostingType("Freight G/L Acc. No.");
            end;
        }
        field(7104; "Link Doc. Date To Posting Date"; Boolean)
        {
            Caption = 'Link Doc. Date to Posting Date';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        JobQueuePriorityErr: Label 'Job Queue Priority must be zero or positive.';
        ProductCoupledErr: Label 'You must choose a record that is not coupled to a product in %1.', Comment = '%1 - Dynamics 365 Sales product name';
        RecordHasBeenRead: Boolean;
        CRMBidirectionalSalesOrderIntEnabledErr: Label 'You cannot disable Archive Orders when Dynamics 365 Sales connection and Bidirectional Sales Order Integration are enabled.';

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure GetLegalStatement(): Text
    begin
        exit('');
    end;

    procedure JobQueueActive(): Boolean
    begin
        Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

    local procedure CheckGLAccPostingTypeBlockedAndGenProdPostingType(AccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAccount.Get(AccNo);
            GLAccount.CheckGLAcc();
            GLAccount.TestField("Gen. Prod. Posting Group");
        end;
    end;
}

