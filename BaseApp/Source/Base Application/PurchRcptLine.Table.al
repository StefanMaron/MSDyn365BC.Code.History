table 121 "Purch. Rcpt. Line"
{
    Caption = 'Purch. Rcpt. Line';
    DrillDownPageID = "Posted Purchase Receipt Lines";
    LookupPageID = "Posted Purchase Receipt Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;

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
            TableRelation = "Purch. Rcpt. Header";
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
            CaptionClass = GetCaptionClass(FieldNo("No."));
            Caption = 'No.';
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge"
            else
            if (Type = const(Resource)) Resource;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Inventory Posting Group"
            ELSE
            IF (Type = CONST("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
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
            AutoFormatExpression = GetCurrencyCodeFromHeader;
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
        field(39; "Item Rcpt. Entry No."; Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(54; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(58; "Qty. Rcd. Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Qty. Rcd. Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order No.';
        }
        field(66; "Order Line No."; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Line No.';
        }
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(70; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(71; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
        }
        field(72; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
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
            TableRelation = "Purch. Rcpt. Line"."Line No." WHERE("Document No." = FIELD("Document No."));
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
            CalcFormula = Lookup ("Purch. Rcpt. Header"."Currency Code" WHERE("No." = FIELD("Document No.")));
            Caption = 'Currency Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            TableRelation = "Purchase Header"."No." WHERE("Document Type" = CONST("Blanket Order"));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            Caption = 'Blanket Order Line No.';
            TableRelation = "Purchase Line"."Line No." WHERE("Document Type" = CONST("Blanket Order"),
                                                              "Document No." = FIELD("Blanket Order No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
        }
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(1002; "Job Line Type"; Option)
        {
            Caption = 'Job Line Type';
            OptionCaption = ' ,Budget,Billable,Both Budget and Billable';
            OptionMembers = " ",Budget,Billable,"Both Budget and Billable";
        }
        field(1003; "Job Unit Price"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Unit Price';
        }
        field(1004; "Job Total Price"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Total Price';
        }
        field(1005; "Job Line Amount"; Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount';
        }
        field(1006; "Job Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Discount Amount';
        }
        field(1007; "Job Line Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(1008; "Job Unit Price (LCY)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Unit Price (LCY)';
        }
        field(1009; "Job Total Price (LCY)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Total Price (LCY)';
        }
        field(1010; "Job Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount (LCY)';
        }
        field(1011; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Disc. Amount (LCY)';
        }
        field(1012; "Job Currency Factor"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Currency Factor';
        }
        field(1013; "Job Currency Code"; Code[20])
        {
            Caption = 'Job Currency Code';
        }
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." WHERE(Status = FILTER(Released | Finished));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                            "Item Filter" = FIELD("No."),
                                            "Variant Filter" = FIELD("Variant Code"));
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
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
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
        field(5601; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,Maintenance';
            OptionMembers = " ","Acquisition Cost",Maintenance;
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
        }
        field(5705; "Cross-Reference No."; Code[20])
        {
            AccessByPermission = TableData "Item Cross Reference" = R;
            Caption = 'Cross-Reference No.';
        }
        field(5706; "Unit of Measure (Cross Ref.)"; Code[10])
        {
            Caption = 'Unit of Measure (Cross Ref.)';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."));
        }
        field(5707; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";
        }
        field(5708; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = IF (Type = CONST(Item)) "Item Category";
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
            TableRelation = "Product Group".Code WHERE("Item Category Code" = FIELD("Item Category Code"));
            ValidateTableRelation = false;
            ObsoleteTag = '15.0';
        }
        field(5714; "Special Order Sales No."; Code[20])
        {
            Caption = 'Special Order Sales No.';
        }
        field(5715; "Special Order Sales Line No."; Integer)
        {
            Caption = 'Special Order Sales Line No.';
        }
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
        }
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
        }
        field(5792; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';
        }
        field(5793; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';
        }
        field(5794; "Planned Receipt Date"; Date)
        {
            Caption = 'Planned Receipt Date';
        }
        field(5795; "Order Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Date';
        }
        field(5811; "Item Charge Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(8509; "Over-Receipt Quantity"; Decimal)
        {
            Caption = 'Over-Receipt Quantity';
            Editable = false;
        }
        field(8510; "Over-Receipt Code"; Code[10])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
            Editable = false;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(99000751; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            TableRelation = "Prod. Order Routing Line"."Operation No." WHERE(Status = FILTER(Released ..),
                                                                              "Prod. Order No." = FIELD("Prod. Order No."),
                                                                              "Routing No." = FIELD("Routing No."));
        }
        field(99000752; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";
        }
        field(99000754; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            TableRelation = "Prod. Order Line"."Line No." WHERE(Status = FILTER(Released ..),
                                                                 "Prod. Order No." = FIELD("Prod. Order No."));
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;
        }
        field(99000759; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key3; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key4; "Item Rcpt. Entry No.")
        {
        }
        key(Key5; "Pay-to Vendor No.")
        {
        }
        key(Key6; "Buy-from Vendor No.")
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
        PurchDocLineComments.SetRange("Document Type", PurchDocLineComments."Document Type"::Receipt);
        PurchDocLineComments.SetRange("No.", "Document No.");
        PurchDocLineComments.SetRange("Document Line No.", "Line No.");
        if not PurchDocLineComments.IsEmpty then
            PurchDocLineComments.DeleteAll();
    end;

    var
        Text000: Label 'Receipt No. %1:';
        Text001: Label 'The program cannot find this purchase line.';
        Currency: Record Currency;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        DimMgt: Codeunit DimensionManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        CurrencyRead: Boolean;

    procedure GetCurrencyCodeFromHeader(): Code[10]
    begin
        if "Document No." = PurchRcptHeader."No." then
            exit(PurchRcptHeader."Currency Code");
        if PurchRcptHeader.Get("Document No.") then
            exit(PurchRcptHeader."Currency Code");
        exit('');
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Document No.", "Line No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Purch. Rcpt. Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure InsertInvLineFromRcptLine(var PurchLine: Record "Purchase Line")
    var
        PurchInvHeader: Record "Purchase Header";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        TranslationHelper: Codeunit "Translation Helper";
        NextLineNo: Integer;
        ExtTextLine: Boolean;
        IsHandled: Boolean;
        DirectUnitCost: Decimal;
    begin
        SetRange("Document No.", "Document No.");

        TempPurchLine := PurchLine;
        if PurchLine.Find('+') then
            NextLineNo := PurchLine."Line No." + 10000
        else
            NextLineNo := 10000;

        if PurchInvHeader."No." <> TempPurchLine."Document No." then
            PurchInvHeader.Get(TempPurchLine."Document Type", TempPurchLine."Document No.");

        if PurchLine."Receipt No." <> "Document No." then begin
            PurchLine.Init();
            PurchLine."Line No." := NextLineNo;
            PurchLine."Document Type" := TempPurchLine."Document Type";
            PurchLine."Document No." := TempPurchLine."Document No.";
            TranslationHelper.SetGlobalLanguageByCode(PurchInvHeader."Language Code");
            PurchLine.Description := StrSubstNo(Text000, "Document No.");
            TranslationHelper.RestoreGlobalLanguage;
            IsHandled := false;
            OnBeforeInsertInvLineFromRcptLineBeforeInsertTextLine(Rec, PurchLine, NextLineNo, IsHandled);
            if not IsHandled then begin
                PurchLine.Insert();
                NextLineNo := NextLineNo + 10000;
            end;
        end;

        TransferOldExtLines.ClearLineNumbers;

        repeat
            ExtTextLine := (TransferOldExtLines.GetNewLineNumber("Attached to Line No.") <> 0);

            if PurchOrderLine.Get(
                 PurchOrderLine."Document Type"::Order, "Order No.", "Order Line No.") and
               not ExtTextLine
            then begin
                if (PurchOrderHeader."Document Type" <> PurchOrderLine."Document Type"::Order) or
                   (PurchOrderHeader."No." <> PurchOrderLine."Document No.")
                then
                    PurchOrderHeader.Get(PurchOrderLine."Document Type"::Order, "Order No.");

                InitCurrency("Currency Code");

                if PurchInvHeader."Prices Including VAT" then begin
                    if not PurchOrderHeader."Prices Including VAT" then
                        PurchOrderLine."Direct Unit Cost" :=
                          Round(
                            PurchOrderLine."Direct Unit Cost" * (1 + PurchOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else begin
                    if PurchOrderHeader."Prices Including VAT" then
                        PurchOrderLine."Direct Unit Cost" :=
                          Round(
                            PurchOrderLine."Direct Unit Cost" / (1 + PurchOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end;
            end else begin
                if ExtTextLine then begin
                    PurchOrderLine.Init();
                    PurchOrderLine."Line No." := "Order Line No.";
                    PurchOrderLine.Description := Description;
                    PurchOrderLine."Description 2" := "Description 2";
                    OnInsertInvLineFromRcptLineOnAfterAssignDescription(Rec, PurchOrderLine);
                end else
                    Error(Text001);
            end;

            CopyFromPurchRcptLine(PurchLine, PurchOrderLine, TempPurchLine, NextLineNo);

            if not ExtTextLine then begin
                IsHandled := false;
                OnInsertInvLineFromRcptLineOnBeforeValidateQuantity(Rec, PurchLine, IsHandled);
                if not IsHandled then
                    PurchLine.Validate(Quantity, Quantity - "Quantity Invoiced");

                OnInsertInvLineFromRcptLineOnAfterCalcQuantities(PurchLine, PurchOrderLine);

                IsHandled := false;
                DirectUnitCost := PurchOrderLine."Direct Unit Cost";
                OnInsertInvLineFromRcptLineOnBeforeSetDirectUnitCost(PurchLine, PurchOrderLine, DirectUnitCost);
                PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
                PurchOrderLine."Line Discount Amount" :=
                  Round(
                    PurchOrderLine."Line Discount Amount" * PurchLine.Quantity / PurchOrderLine.Quantity,
                    Currency."Amount Rounding Precision");
                if PurchInvHeader."Prices Including VAT" then begin
                    if not PurchOrderHeader."Prices Including VAT" then
                        PurchOrderLine."Line Discount Amount" :=
                          Round(
                            PurchOrderLine."Line Discount Amount" *
                            (1 + PurchOrderLine."VAT %" / 100), Currency."Amount Rounding Precision");
                end else
                    if PurchOrderHeader."Prices Including VAT" then
                        PurchOrderLine."Line Discount Amount" :=
                          Round(
                            PurchOrderLine."Line Discount Amount" /
                            (1 + PurchOrderLine."VAT %" / 100), Currency."Amount Rounding Precision");
                PurchLine.Validate("Line Discount Amount", PurchOrderLine."Line Discount Amount");
                PurchLine."Line Discount %" := PurchOrderLine."Line Discount %";
                PurchLine.UpdatePrePaymentAmounts;
                if PurchOrderLine.Quantity = 0 then
                    PurchLine.Validate("Inv. Discount Amount", 0)
                else
                    PurchLine.Validate(
                      "Inv. Discount Amount",
                      Round(
                        PurchOrderLine."Inv. Discount Amount" * PurchLine.Quantity / PurchOrderLine.Quantity,
                        Currency."Amount Rounding Precision"));
            end;

            PurchLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                "Line No.",
                NextLineNo,
                "Attached to Line No.");
            PurchLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            PurchLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            PurchLine."Dimension Set ID" := "Dimension Set ID";

            if "Sales Order No." = '' then
                PurchLine."Drop Shipment" := false
            else
                PurchLine."Drop Shipment" := true;

            OnBeforeInsertInvLineFromRcptLine(Rec, PurchLine, PurchOrderLine);
            PurchLine.Insert();
            OnAfterInsertInvLineFromRcptLine(PurchLine, PurchOrderLine, NextLineNo, Rec);

            ItemTrackingMgt.CopyHandledItemTrkgToInvLine(PurchOrderLine, PurchLine);

            NextLineNo := NextLineNo + 10000;
            if "Attached to Line No." = 0 then
                SetRange("Attached to Line No.", "Line No.");
        until (Next = 0) or ("Attached to Line No." = 0);
    end;

    local procedure CopyFromPurchRcptLine(var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line"; TempPurchLine: Record "Purchase Line"; NextLineNo: Integer)
    begin
        PurchLine := PurchOrderLine;
        PurchLine."Line No." := NextLineNo;
        PurchLine."Document Type" := TempPurchLine."Document Type";
        PurchLine."Document No." := TempPurchLine."Document No.";
        PurchLine."Variant Code" := "Variant Code";
        PurchLine."Location Code" := "Location Code";
        PurchLine."Quantity (Base)" := 0;
        PurchLine.Quantity := 0;
        PurchLine."Outstanding Qty. (Base)" := 0;
        PurchLine."Outstanding Quantity" := 0;
        PurchLine."Quantity Received" := 0;
        PurchLine."Qty. Received (Base)" := 0;
        PurchLine."Quantity Invoiced" := 0;
        PurchLine."Qty. Invoiced (Base)" := 0;
        PurchLine.Amount := 0;
        PurchLine."Amount Including VAT" := 0;
        PurchLine."Sales Order No." := '';
        PurchLine."Sales Order Line No." := 0;
        PurchLine."Drop Shipment" := false;
        PurchLine."Special Order Sales No." := '';
        PurchLine."Special Order Sales Line No." := 0;
        PurchLine."Special Order" := false;
        PurchLine."Receipt No." := "Document No.";
        PurchLine."Receipt Line No." := "Line No.";
        PurchLine."Appl.-to Item Entry" := 0;

        OnAfterCopyFromPurchRcptLine(PurchLine, Rec);
    end;

    procedure GetPurchInvLines(var TempPurchInvLine: Record "Purch. Inv. Line" temporary)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        TempPurchInvLine.Reset();
        TempPurchInvLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        ItemLedgEntry.SetFilter("Invoiced Quantity", '<>0');
        if ItemLedgEntry.FindSet then begin
            ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
            ValueEntry.SetFilter("Invoiced Quantity", '<>0');
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                if ValueEntry.FindSet then
                    repeat
                        if ValueEntry."Document Type" = ValueEntry."Document Type"::"Purchase Invoice" then
                            if PurchInvLine.Get(ValueEntry."Document No.", ValueEntry."Document Line No.") then begin
                                TempPurchInvLine.Init();
                                TempPurchInvLine := PurchInvLine;
                                if TempPurchInvLine.Insert() then;
                            end;
                    until ValueEntry.Next = 0;
            until ItemLedgEntry.Next = 0;
        end;
    end;

    procedure CalcReceivedPurchNotReturned(var RemainingQty: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TotalCostLCY: Decimal;
        TotalQtyBase: Decimal;
    begin
        RemainingQty := 0;
        if (Type <> Type::Item) or (Quantity <= 0) then begin
            RevUnitCostLCY := "Unit Cost (LCY)";
            exit;
        end;

        RevUnitCostLCY := 0;
        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        if ItemLedgEntry.FindSet then
            repeat
                RemainingQty := RemainingQty + ItemLedgEntry."Remaining Quantity";
                if ExactCostReverse then begin
                    ItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
                    TotalCostLCY :=
                      TotalCostLCY + ItemLedgEntry."Cost Amount (Expected)" + ItemLedgEntry."Cost Amount (Actual)";
                    TotalQtyBase := TotalQtyBase + ItemLedgEntry.Quantity;
                end;
            until ItemLedgEntry.Next = 0;

        if ExactCostReverse and (RemainingQty <> 0) and (TotalQtyBase <> 0) then
            RevUnitCostLCY := Abs(TotalCostLCY / TotalQtyBase) * "Qty. per Unit of Measure"
        else
            RevUnitCostLCY := "Unit Cost (LCY)";

        RemainingQty := CalcQty(RemainingQty);
    end;

    local procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            exit(QtyBase);
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision));
    end;

    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", "Document No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    procedure ShowItemPurchInvLines()
    var
        TempPurchInvLine: Record "Purch. Inv. Line" temporary;
    begin
        if Type = Type::Item then begin
            GetPurchInvLines(TempPurchInvLine);
            PAGE.RunModal(PAGE::"Posted Purchase Invoice Lines", TempPurchInvLine);
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if (Currency.Code = CurrencyCode) and CurrencyRead then
            exit;

        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision;
        CurrencyRead := true;
    end;

    procedure ShowLineComments()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.ShowComments(PurchCommentLine."Document Type"::Receipt, "Document No.", "Line No.");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure InitFromPurchLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line")
    var
        Factor: Decimal;
    begin
        Init;
        TransferFields(PurchLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := PurchRcptHeader."Posting Date";
        "Document No." := PurchRcptHeader."No.";
        Quantity := PurchLine."Qty. to Receive";
        "Quantity (Base)" := PurchLine."Qty. to Receive (Base)";
        if Abs(PurchLine."Qty. to Invoice") > Abs(PurchLine."Qty. to Receive") then begin
            "Quantity Invoiced" := PurchLine."Qty. to Receive";
            "Qty. Invoiced (Base)" := PurchLine."Qty. to Receive (Base)";
        end else begin
            "Quantity Invoiced" := PurchLine."Qty. to Invoice";
            "Qty. Invoiced (Base)" := PurchLine."Qty. to Invoice (Base)";
        end;
        "Qty. Rcd. Not Invoiced" := Quantity - "Quantity Invoiced";
        if PurchLine."Document Type" = PurchLine."Document Type"::Order then begin
            "Order No." := PurchLine."Document No.";
            "Order Line No." := PurchLine."Line No.";
        end;
        if (PurchLine.Quantity <> 0) and ("Job No." <> '') then begin
            Factor := PurchLine."Qty. to Receive" / PurchLine.Quantity;
            if Factor <> 1 then
                UpdateJobPrices(Factor);
        end;

        OnAfterInitFromPurchLine(PurchRcptHeader, PurchLine, Rec);
    end;

    procedure FormatType(): Text
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Type = Type::" " then
            exit(PurchaseLine.FormatType);

        exit(Format(Type));
    end;

    local procedure UpdateJobPrices(Factor: Decimal)
    begin
        "Job Total Price" :=
          Round("Job Total Price" * Factor, Currency."Amount Rounding Precision");
        "Job Total Price (LCY)" :=
          Round("Job Total Price (LCY)" * Factor, Currency."Amount Rounding Precision");
        "Job Line Amount" :=
          Round("Job Line Amount" * Factor, Currency."Amount Rounding Precision");
        "Job Line Amount (LCY)" :=
          Round("Job Line Amount (LCY)" * Factor, Currency."Amount Rounding Precision");
        "Job Line Discount Amount" :=
          Round("Job Line Discount Amount" * Factor, Currency."Amount Rounding Precision");
        "Job Line Disc. Amount (LCY)" :=
          Round("Job Line Disc. Amount (LCY)" * Factor, Currency."Amount Rounding Precision");
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Purch. Rcpt. Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        case FieldNumber of
            FieldNo("No."):
                exit(StrSubstNo('3,%1', GetFieldCaption(FieldNumber)));
        end;
    end;

    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchRcptLine(var PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchLine(PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvLineFromRcptLine(var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line"; NextLineNo: Integer; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRcptLineBeforeInsertTextLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchLine: Record "Purchase Line"; var NextLineNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRcptLineOnAfterAssignDescription(var PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRcptLineOnAfterCalcQuantities(var PurchaseLine: Record "Purchase Line"; PurchaseOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRcptLineOnBeforeSetDirectUnitCost(var PurchaseLine: Record "Purchase Line"; PurchaseOrderLine: Record "Purchase Line"; var DirectUnitCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRcptLineOnBeforeValidateQuantity(PurchRcptLine: Record "Purch. Rcpt. Line"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
}

