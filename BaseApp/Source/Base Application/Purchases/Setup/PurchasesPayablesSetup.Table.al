namespace Microsoft.Purchases.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Structure;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using System.Environment;
#if not CLEAN23
using System.Environment.Configuration;
using System.Telemetry;
#endif
using System.Threading;

table 312 "Purchases & Payables Setup"
{
    Caption = 'Purchases & Payables Setup';
    DrillDownPageID = "Purchases & Payables Setup";
    LookupPageID = "Purchases & Payables Setup";
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
        field(6; "Receipt on Invoice"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Receipt on Invoice';
        }
        field(7; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
        }
        field(8; "Ext. Doc. No. Mandatory"; Boolean)
        {
            Caption = 'Ext. Doc. No. Mandatory';
            InitValue = true;
        }
        field(9; "Vendor Nos."; Code[20])
        {
            Caption = 'Vendor Nos.';
            TableRelation = "No. Series";
        }
        field(10; "Quote Nos."; Code[20])
        {
            Caption = 'Quote Nos.';
            TableRelation = "No. Series";
        }
        field(11; "Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
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
        field(16; "Posted Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Posted Receipt Nos.';
            TableRelation = "No. Series";
        }
        field(19; "Blanket Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Blanket Order Nos.';
            TableRelation = "No. Series";
        }
        field(20; "Calc. Inv. Discount"; Boolean)
        {
            AccessByPermission = TableData "Vendor Invoice Disc." = R;
            Caption = 'Calc. Inv. Discount';
        }
        field(21; "Appln. between Currencies"; Option)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Appln. between Currencies';
            OptionCaption = 'None,EMU,All';
            OptionMembers = "None",EMU,All;
        }
        field(22; "Copy Comments Blanket to Order"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Copy Comments Blanket to Order';
            InitValue = true;
        }
        field(23; "Copy Comments Order to Invoice"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Copy Comments Order to Invoice';
            InitValue = true;
        }
        field(24; "Copy Comments Order to Receipt"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Copy Comments Order to Receipt';
            InitValue = true;
        }
        field(25; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';
        }
        field(26; "Calc. Inv. Disc. per VAT ID"; Boolean)
        {
            Caption = 'Calc. Inv. Disc. per VAT ID';
        }
        field(27; "Posted Prepmt. Inv. Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Inv. Nos.';
            TableRelation = "No. Series";
        }
        field(28; "Posted Prepmt. Cr. Memo Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Cr. Memo Nos.';
            TableRelation = "No. Series";
        }
        field(29; "Check Prepmt. when Posting"; Boolean)
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

                PrepaymentMgt.CreateAndStartJobQueueEntryPurchase("Prepmt. Auto Update Frequency");
            end;
        }
        field(35; "Default Posting Date"; Enum "Default Posting Date")
        {
            Caption = 'Default Posting Date';
        }
        field(36; "Default Qty. to Receive"; Option)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Default Qty. to Receive';
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
                    Error(Text001);
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
                    Error(Text001);
            end;
        }
        field(43; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
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
        field(49; "Document Default Line Type"; Enum "Purchase Line Type")
        {
            Caption = 'Document Default Line Type';
        }
        field(51; "Default G/L Account Quantity"; Boolean)
        {
            Caption = 'Default G/L Account Quantity';
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
        }
        field(54; "Archive Blanket Orders"; Boolean)
        {
            Caption = 'Archive Blanket Orders';
        }
        field(55; "Archive Return Orders"; Boolean)
        {
            Caption = 'Archive Return Orders';
        }
        field(56; "Ignore Updated Addresses"; Boolean)
        {
            Caption = 'Ignore Updated Addresses';
        }
        field(57; "Create Item from Item No."; Boolean)
        {
            Caption = 'Create Item from Item No.';
        }
        field(58; "Copy Vendor Name to Entries"; Boolean)
        {
            Caption = 'Copy Vendor Name to Entries';

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
            begin
                if "Copy Vendor Name to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(59; "Copy Inv. No. To Pmt. Ref."; Boolean)
        {
            Caption = 'Copy Invoice No. To Payment Reference';
        }
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            DataClassification = SystemMetadata;
        }
        field(170; "Insert Std. Purch. Lines Mode"; Option)
        {
            Caption = 'Insert Std. Purch. Lines Mode';
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
        field(200; "P. Invoice Template Name"; Code[10])
        {
            Caption = 'Purch. Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(201; "P. Cr. Memo Template Name"; Code[10])
        {
            Caption = 'Purch. Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(202; "P. Prep. Inv. Template Name"; Code[10])
        {
            Caption = 'P. Prep. Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(203; "P. Prep. Cr.Memo Template Name"; Code[10])
        {
            Caption = 'Purch. Prep. Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(204; "IC Purch. Invoice Templ. Name"; Code[10])
        {
            Caption = 'IC Jnl. Templ. Purch. Invoice';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        field(205; "IC Purch. Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Jnl. Templ. Purch. Cr. Memo';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        field(210; "Copy Line Descr. to G/L Entry"; Boolean)
        {
            Caption = 'Copy Line Descr. to G/L Entry';
            DataClassification = SystemMetadata;
        }
        field(810; "Invoice Posting Setup"; Enum "Purchase Invoice Posting")
        {
            Caption = 'Invoice Posting Setup';
            ObsoleteReason = 'Replaced by direct selection of posting interface in codeunits.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(1217; "Debit Acc. for Non-Item Lines"; Code[20])
        {
            Caption = 'Debit Acc. for Non-Item Lines';
            TableRelation = "G/L Account" where("Direct Posting" = const(true),
                                                 "Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        field(1218; "Credit Acc. for Non-Item Lines"; Code[20])
        {
            Caption = 'Credit Acc. for Non-Item Lines';
            TableRelation = "G/L Account" where("Direct Posting" = const(true),
                                                 "Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        field(5775; "Auto Post Non-Invt. via Whse."; Enum "Non-Invt. Item Whse. Policy")
        {
            Caption = 'Auto Post Non-Invt. via Whse.';
        }
        field(5800; "Posted Return Shpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Posted Return Shpt. Nos.';
            TableRelation = "No. Series";
        }
        field(5801; "Copy Cmts Ret.Ord. to Ret.Shpt"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Ret.Shpt';
            InitValue = true;
        }
        field(5802; "Copy Cmts Ret.Ord. to Cr. Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Cr. Memo';
            InitValue = true;
        }
        field(6600; "Return Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Order Nos.';
            TableRelation = "No. Series";
        }
        field(6601; "Return Shipment on Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Shipment on Credit Memo';
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
                PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Purchase);
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
            TableRelation = "Price List Header" where("Price Type" = const(Purchase), "Source Group" = const(Vendor), "Allow Updating Defaults" = const(true));
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if Page.RunModal(Page::"Purchase Price Lists", PriceListHeader) = Action::LookupOK then begin
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
        field(7004; "Link Doc. Date To Posting Date"; Boolean)
        {
            Caption = 'Link Doc. Date to Posting Date';
            DataClassification = SystemMetadata;
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
#pragma warning disable AA0074
        Text001: Label 'Job Queue Priority must be zero or positive.';
#pragma warning restore AA0074
        RecordHasBeenRead: Boolean;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure JobQueueActive(): Boolean
    begin
        Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;
}

