namespace Microsoft.Purchases.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Structure;
using System.Security.User;

table 6651 "Return Shipment Line"
{
    Caption = 'Return Shipment Line';
    LookupPageID = "Posted Return Shipment Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Return Shipment Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge"
            else
            if (Type = const(Resource)) Resource;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(31; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
        }
        field(39; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(54; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(70; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Return Shipment Line"."Line No." where("Document No." = field("Document No."));
        }
        field(81; "Entry Point"; Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(88; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(91; "Currency Code"; Code[10])
        {
            CalcFormula = lookup("Return Shipment Header"."Currency Code" where("No." = field("Document No.")));
            Caption = 'Currency Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Blanket Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Blanket Order Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                           "Document No." = field("Blanket Order No."));
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"),
                                            "Item Filter" = field("No."),
                                            "Variant Filter" = field("Variant Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            Caption = 'FA Posting Type';
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
            ValidateTableRelation = true;
        }
        field(5705; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
            ObsoleteReason = 'Cross-Reference replaced by Item Reference feature.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(5706; "Unit of Measure (Cross Ref.)"; Code[10])
        {
            Caption = 'Unit of Measure (Cross Ref.)';
            ObsoleteReason = 'Cross-Reference replaced by Item Reference feature.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(5707; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";
            ObsoleteReason = 'Cross-Reference replaced by Item Reference feature.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(5708; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';
            ObsoleteReason = 'Cross-Reference replaced by Item Reference feature.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = if (Type = const(Item)) "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5712; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure (Item Ref.)';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5805; "Return Qty. Shipped Not Invd."; Decimal)
        {
            Caption = 'Return Qty. Shipped Not Invd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5811; "Item Charge Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            Editable = false;
        }
        field(6602; "Return Order No."; Code[20])
        {
            Caption = 'Return Order No.';
            Editable = false;
        }
        field(6603; "Return Order Line No."; Integer)
        {
            Caption = 'Return Order Line No.';
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Return Order No.", "Return Order Line No.")
        {
        }
        key(Key3; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key4; "Pay-to Vendor No.")
        {
        }
        key(Key5; "Buy-from Vendor No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PurchDocLineComments: Record "Purch. Comment Line";
    begin
        PurchDocLineComments.SetRange("Document Type", PurchDocLineComments."Document Type"::"Posted Return Shipment");
        PurchDocLineComments.SetRange("No.", "Document No.");
        PurchDocLineComments.SetRange("Document Line No.", "Line No.");
        if not PurchDocLineComments.IsEmpty() then
            PurchDocLineComments.DeleteAll();
    end;

    var
        Currency: Record Currency;
        ReturnShptHeader: Record "Return Shipment Header";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Return Shipment No. %1:';
#pragma warning restore AA0470
        Text001: Label 'The program cannot find this purchase line.';
#pragma warning restore AA0074
        CurrencyRead: Boolean;

    procedure GetCurrencyCode(): Code[10]
    begin
        if "Document No." = ReturnShptHeader."No." then
            exit(ReturnShptHeader."Currency Code");
        if ReturnShptHeader.Get("Document No.") then
            exit(ReturnShptHeader."Currency Code");
        exit('');
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID",
          StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Return Shipment Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure InsertInvLineFromRetShptLine(var PurchLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NextLineNo: Integer;
        ExtTextLine: Boolean;
        IsHandled: Boolean;
    begin
        SetRange("Document No.", "Document No.");

        TempPurchLine := PurchLine;
        if PurchLine.Find('+') then
            NextLineNo := PurchLine."Line No." + 10000
        else
            NextLineNo := 10000;

        if PurchHeader."No." <> TempPurchLine."Document No." then
            PurchHeader.Get(TempPurchLine."Document Type", TempPurchLine."Document No.");

        if PurchLine."Return Shipment No." <> "Document No." then begin
            PurchLine.Init();
            PurchLine."Line No." := NextLineNo;
            PurchLine."Document Type" := TempPurchLine."Document Type";
            PurchLine."Document No." := TempPurchLine."Document No.";
            PurchLine.Description := StrSubstNo(Text000, "Document No.");
            IsHandled := false;
            OnInsertInvLineFromRetShptLineOnBeforePurchLineInsert(Rec, PurchLine, NextLineNo, IsHandled);
            if not IsHandled then begin
                PurchLine.Insert();
                NextLineNo := NextLineNo + 10000;
            end;
        end;

        OnInsertInvLineFromRetShptLineOnBeforeClearLineNumbers(Rec, PurchLine, NextLineNo, TempPurchLine);
        TransferOldExtLines.ClearLineNumbers();
        PurchSetup.Get();
        repeat
            ExtTextLine := (Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0);
            if ExtTextLine then
                TransferOldExtLines.GetNewLineNumber("Attached to Line No.")
            else
                "Attached to Line No." := 0;

            if not PurchOrderLine.Get(
                 PurchOrderLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.")
            then begin
                if ExtTextLine then begin
                    PurchOrderLine.Init();
                    PurchOrderLine."Line No." := "Return Order Line No.";
                    PurchOrderLine.Description := Description;
                    PurchOrderLine."Description 2" := "Description 2";
                end else
                    Error(Text001);
            end else begin
                if (PurchHeader2."Document Type" <> PurchOrderLine."Document Type"::"Return Order") or
                   (PurchHeader2."No." <> PurchOrderLine."Document No.")
                then
                    PurchHeader2.Get(PurchOrderLine."Document Type"::"Return Order", "Return Order No.");

                InitCurrency("Currency Code");

                if PurchHeader."Prices Including VAT" then begin
                    if not PurchHeader2."Prices Including VAT" then
                        PurchOrderLine."Direct Unit Cost" :=
                          Round(
                            PurchOrderLine."Direct Unit Cost" * (1 + PurchOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else
                    if PurchHeader2."Prices Including VAT" then
                        PurchOrderLine."Direct Unit Cost" :=
                          Round(
                            PurchOrderLine."Direct Unit Cost" / (1 + PurchOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
            end;
            PurchLine := PurchOrderLine;
            PurchLine."Line No." := NextLineNo;
            PurchLine."Document Type" := TempPurchLine."Document Type";
            PurchLine."Document No." := TempPurchLine."Document No.";
            PurchLine."Variant Code" := "Variant Code";
            PurchLine."Location Code" := "Location Code";
            PurchLine."Return Reason Code" := "Return Reason Code";
            PurchLine."Quantity (Base)" := 0;
            PurchLine.Quantity := 0;
            PurchLine."Outstanding Qty. (Base)" := 0;
            PurchLine."Outstanding Quantity" := 0;
            PurchLine."Return Qty. Shipped" := 0;
            PurchLine."Return Qty. Shipped (Base)" := 0;
            PurchLine."Quantity Invoiced" := 0;
            PurchLine."Qty. Invoiced (Base)" := 0;
            PurchLine."Sales Order No." := '';
            PurchLine."Sales Order Line No." := 0;
            PurchLine."Drop Shipment" := false;
            PurchLine."Return Shipment No." := "Document No.";
            PurchLine."Return Shipment Line No." := "Line No.";
            PurchLine."Appl.-to Item Entry" := 0;
            OnAfterCopyFieldsFromReturnShipmentLine(Rec, PurchLine);

            if not ExtTextLine then begin
                IsHandled := false;
                OnInsertInvLineFromRetShptLineOnBeforeValidatePurchaseLine(Rec, PurchLine, IsHandled, PurchHeader);
                if not IsHandled then
                    PurchLine.Validate(Quantity, Quantity - "Quantity Invoiced");

                CopyPurchLineCostAndDiscountFromPurchOrderLine(PurchLine, PurchOrderLine);
            end;
            PurchLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                "Line No.",
                NextLineNo,
                "Attached to Line No.");
            PurchLine."Shortcut Dimension 1 Code" := PurchOrderLine."Shortcut Dimension 1 Code";
            PurchLine."Shortcut Dimension 2 Code" := PurchOrderLine."Shortcut Dimension 2 Code";
            PurchLine."Dimension Set ID" := PurchOrderLine."Dimension Set ID";

            IsHandled := false;
            OnBeforeInsertInvLineFromRetShptLine(PurchLine, PurchOrderLine, Rec, IsHandled, NextLineNo);
            if not IsHandled then begin
                PurchLine.Insert();
                NextLineNo := NextLineNo + 10000;
            end;
            OnAfterInsertInvLineFromRetShptLine(PurchLine, PurchOrderLine, Rec);

            ItemTrackingMgt.CopyHandledItemTrkgToInvLine(PurchOrderLine, PurchLine);

            if "Attached to Line No." = 0 then begin
                SetRange("Attached to Line No.", "Line No.");
                SetRange(Type, Type::" ");
            end;
        until (Next() = 0) or ("Attached to Line No." = 0);
    end;

    local procedure CopyPurchLineCostAndDiscountFromPurchOrderLine(var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchLineCostAndDiscountFromPurchOrderLine(PurchLine, PurchOrderLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Validate("Direct Unit Cost", PurchOrderLine."Direct Unit Cost");
        PurchLine.Validate("Line Discount %", PurchOrderLine."Line Discount %");
        if PurchOrderLine.Quantity = 0 then
            PurchLine.Validate("Inv. Discount Amount", 0)
        else
            PurchLine.Validate(
              "Inv. Discount Amount",
              Round(
                PurchOrderLine."Inv. Discount Amount" * PurchLine.Quantity / PurchOrderLine.Quantity,
                Currency."Amount Rounding Precision"));
    end;

    procedure GetPurchCrMemoLines(var TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        TempPurchCrMemoLine.Reset();
        TempPurchCrMemoLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        ItemLedgEntry.SetFilter("Invoiced Quantity", '<>0');
        if ItemLedgEntry.FindSet() then begin
            ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
            ValueEntry.SetFilter("Invoiced Quantity", '<>0');
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                if ValueEntry.FindSet() then
                    repeat
                        if ValueEntry."Document Type" = ValueEntry."Document Type"::"Purchase Credit Memo" then
                            if PurchCrMemoLine.Get(ValueEntry."Document No.", ValueEntry."Document Line No.") then begin
                                TempPurchCrMemoLine.Init();
                                TempPurchCrMemoLine := PurchCrMemoLine;
                                if TempPurchCrMemoLine.Insert() then;
                            end;
                    until ValueEntry.Next() = 0;
            until ItemLedgEntry.Next() = 0;
        end;
    end;

    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", "Document No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Return Shipment");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    procedure ShowItemPurchCrMemoLines()
    var
        TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary;
    begin
        if Type = Type::Item then begin
            GetPurchCrMemoLines(TempPurchCrMemoLine);
            PAGE.RunModal(0, TempPurchCrMemoLine);
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if (Currency.Code = CurrencyCode) and CurrencyRead then
            exit;

        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();
        CurrencyRead := true;
    end;

    procedure ShowLineComments()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.ShowComments(
            PurchCommentLine."Document Type"::"Posted Return Shipment".AsInteger(), "Document No.", "Line No.");
    end;

    procedure InitFromPurchLine(ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line")
    begin
        Init();
        TransferFields(PurchLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := ReturnShptHeader."Posting Date";
        "Document No." := ReturnShptHeader."No.";
        Quantity := PurchLine."Return Qty. to Ship";
        "Quantity (Base)" := PurchLine."Return Qty. to Ship (Base)";
        if Abs(PurchLine."Qty. to Invoice") > Abs(PurchLine."Return Qty. to Ship") then begin
            "Quantity Invoiced" := PurchLine."Return Qty. to Ship";
            "Qty. Invoiced (Base)" := PurchLine."Return Qty. to Ship (Base)";
        end else begin
            "Quantity Invoiced" := PurchLine."Qty. to Invoice";
            "Qty. Invoiced (Base)" := PurchLine."Qty. to Invoice (Base)";
        end;
        "Return Qty. Shipped Not Invd." := Quantity - "Quantity Invoiced";
        if PurchLine."Document Type" = PurchLine."Document Type"::"Return Order" then begin
            "Return Order No." := PurchLine."Document No.";
            "Return Order Line No." := PurchLine."Line No.";
        end;

        OnAfterInitFromPurchLine(ReturnShptHeader, PurchLine, Rec);
    end;

    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetPurchasesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetPurchasesFilter());
            FilterGroup(0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLineCostAndDiscountFromPurchOrderLine(var PurchaseLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchLine(ReturnShptHeader: Record "Return Shipment Header"; PurchLine: Record "Purchase Line"; var ReturnShptLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvLineFromRetShptLine(var PurchLine: Record "Purchase Line"; var PurchOrderLine: Record "Purchase Line"; var ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRetShptLine(var PurchLine: Record "Purchase Line"; var PurchOrderLine: Record "Purchase Line"; var ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetShptLineOnBeforeValidatePurchaseLine(var ReturnShipmentLine: Record "Return Shipment Line"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetShptLineOnBeforePurchLineInsert(var ReturnShipmentLine: Record "Return Shipment Line"; var PurchaseLine: Record "Purchase Line"; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetShptLineOnBeforeClearLineNumbers(var ReturnShipmentLine: Record "Return Shipment Line"; var PurchLine: Record "Purchase Line"; var NextLineNo: Integer; var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ReturnShipmentLine: Record "Return Shipment Line"; var IsHandled: Boolean)
    begin
    end;
}

