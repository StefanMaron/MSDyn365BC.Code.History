table 311 "Sales & Receivables Setup"
{
    Caption = 'Sales & Receivables Setup';
    DrillDownPageID = "Sales & Receivables Setup";
    LookupPageID = "Sales & Receivables Setup";

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
        field(47; "Report Output Type"; Option)
        {
            Caption = 'Report Output Type';
            DataClassification = CustomerContent;
            OptionCaption = 'PDF,,,Print';
            OptionMembers = PDF,,,Print;

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
#if CLEAN20
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'The field is part of the removed functionality.';
            ObsoleteTag = '20.0';
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

#if not CLEAN20
            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Allow Multiple Posting Groups" then
                    if EnvironmentInformation.IsProduction() then
                        error(MultiplePostingGroupsNotAllowedErr);
            end;
#endif
        }
        field(200; "Quote Validity Calculation"; DateFormula)
        {
            Caption = 'Quote Validity Calculation';
            DataClassification = SystemMetadata;
        }
        field(201; "S. Invoice Template Name"; Code[10])
        {
            Caption = 'Sales Invoice Journal Template';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Sales));
        }
        field(202; "S. Cr. Memo Template Name"; Code[10])
        {
            Caption = 'Sales Cr. Memo Journal Template';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Sales));
        }
        field(203; "S. Prep. Inv. Template Name"; Code[10])
        {
            Caption = 'Sales Prep. Invoice Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Sales));
        }
        field(204; "S. Prep. Cr.Memo Template Name"; Code[10])
        {
            Caption = 'Sales Prep. Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Sales));
        }
        field(205; "IC Sales Invoice Template Name"; Code[10])
        {
            Caption = 'IC Sales Invoice Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Intercompany));
        }
        field(206; "IC Sales Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Sales Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Intercompany));
        }
        field(207; "Fin. Charge Jnl. Template Name"; Code[10])
        {
            Caption = 'Finance Charge Journal Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Sales));
        }
        field(208; "Reminder Journal Template Name"; Code[10])
        {
            Caption = 'Reminder Journal Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(Sales));
        }
        field(209; "Reminder Journal Batch Name"; Code[10])
        {
            Caption = 'Reminder Journal Batch Name';
            TableRelation = IF ("Reminder Journal Template Name" = FILTER(<> '')) "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Reminder Journal Template Name"));

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
            TableRelation = IF ("Fin. Charge Jnl. Template Name" = FILTER(<> '')) "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Fin. Charge Jnl. Template Name"));

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
#if CLEAN20
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
                EnvironmentInfo: Codeunit "Environment Information";
                InvoicePostingInterface: Interface "Invoice Posting";
            begin
                if "Invoice Posting Setup" <> "Sales Invoice Posting"::"Invoice Posting (Default)" then begin
                    if EnvironmentInfo.IsProduction() then
                        error(InvoicePostingNotAllowedErr);

                    AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, "Invoice Posting Setup".AsInteger());
                    InvoicePostingInterface := "Invoice Posting Setup";
                    InvoicePostingInterface.Check(Database::"Sales Header");
                end;
            end;
#endif
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
            TableRelation = IF ("Write-in Product Type" = CONST(Item)) Item."No." WHERE(Type = FILTER(Service | "Non-Inventory"))
            ELSE
            IF ("Write-in Product Type" = CONST(Resource)) Resource."No.";

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
            TableRelation = "Price List Header" where("Price Type" = Const(Sale), "Source Group" = Const(Customer), "Allow Updating Defaults" = const(true));
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
        field(11760; "G/L Entry as Doc. Lines (Acc.)"; Boolean)
        {
            Caption = 'G/L Entry as Doc. Lines (Acc.)';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by "Copy Line Descr. to G/L Entry" field. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '19.0';
        }
        field(11761; "G/L Entry as Doc. Lines (Item)"; Boolean)
        {
            Caption = 'G/L Entry as Doc. Lines (Item)';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of general ledger entry description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '19.0';
        }
        field(11762; "G/L Entry as Doc. Lines (FA)"; Boolean)
        {
            Caption = 'G/L Entry as Doc. Lines (FA)';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of general ledger entry description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '19.0';
        }
        field(11763; "G/L Entry as Doc. Lines (Res.)"; Boolean)
        {
            Caption = 'G/L Entry as Doc. Lines (Res.)';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of general ledger entry description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '19.0';
        }
        field(11764; "G/L Entry as Doc. Lines (Char)"; Boolean)
        {
            Caption = 'G/L Entry as Doc. Lines (Char)';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of general ledger entry description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '19.0';
        }
        field(11765; "Posting Desc. Code"; Code[10])
        {
            Caption = 'Posting Desc. Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of posting description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11766; "Default VAT Date"; Option)
        {
            Caption = 'Default VAT Date';
            OptionCaption = 'Posting Date,Document Date,Blank';
            OptionMembers = "Posting Date","Document Date",Blank;
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech. (Prolonged to support Advance Letters)';
            ObsoleteTag = '17.0';
        }
        field(11767; "Allow Alter Posting Groups"; Boolean)
        {
            Caption = 'Allow Alter Posting Groups';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11768; "Automatic Adv. Invoice Posting"; Boolean)
        {
            Caption = 'Automatic Adv. Invoice Posting';
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11772; "Reas.Cd. on Tax Corr.Doc.Mand."; Boolean)
        {
            Caption = 'Reas.Cd. on Tax Corr.Doc.Mand.';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11773; "Pmt.Disc.Tax Corr.Doc. Nos."; Code[20])
        {
            Caption = 'Pmt.Disc.Tax Corr.Doc. Nos.';
            TableRelation = "No. Series";
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11774; "Copy As Tax Corr. Document"; Boolean)
        {
            Caption = 'Copy As Tax Corr. Document';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11775; "Reason Code For Payment Disc."; Code[10])
        {
            Caption = 'Reason Code For Payment Disc.';
            TableRelation = "Reason Code".Code;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11777; "Credit Memo Confirmation"; Boolean)
        {
            Caption = 'Credit Memo Confirmation';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Postponing VAT on Sales Cr.Memo will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11778; "Multiple Interest Rates"; Boolean)
        {
            Caption = 'Multiple Interest Rates';
#if not CLEAN20
            ObsoleteState = Pending;
            ObsoleteTag = '20.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
#endif
            ObsoleteReason = 'Replaced by Finance Charge Interest Rate';
        }
        field(11779; "Fin. Charge Posting Desc. Code"; Code[10])
        {
            Caption = 'Fin. Charge Posting Desc. Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of posting description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31000; "Advance Letter Nos."; Code[20])
        {
            Caption = 'Advance Letter Nos.';
            TableRelation = "No. Series";
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(31001; "Advance Invoice Nos."; Code[20])
        {
            Caption = 'Advance Invoice Nos.';
            TableRelation = "No. Series";
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(31002; "Advance Credit Memo Nos."; Code[20])
        {
            Caption = 'Advance Credit Memo Nos.';
            TableRelation = "No. Series";
#if CLEAN19
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '19.0';
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
        Text001: Label 'Job Queue Priority must be zero or positive.';
        ProductCoupledErr: Label 'You must choose a record that is not coupled to a product in %1.', Comment = '%1 - Dynamics 365 Sales product name';
#if not CLEAN20
        InvoicePostingNotAllowedErr: Label 'Use of alternative invoice posting interfaces in production environment is currently not allowed.';
        MultiplePostingGroupsNotAllowedErr: Label 'Use of multiple posting groups in production environment is currently not allowed.';
#endif
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
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TestField("Gen. Prod. Posting Group");
        end;
    end;
}

